require "rails_helper"
require "base64"

RSpec.describe "Characters API", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }
  let(:project) { create(:project, user: user) }

  # Drives a project's character to `awaiting_approval` with statuses in sync.
  def awaiting_approval_character(proj = project)
    character = create(:character, project: proj)
    proj.update!(status: :draft)
    character.transition_to!(:generating)
    character.transition_to!(:awaiting_approval)
    character
  end

  describe "POST /api/v1/projects/:project_id/character" do
    it "creates a pending character" do
      post "/api/v1/projects/#{project.id}/character",
           params: { character: { name: "Rusty", description: "a fox", attributes: { species: "fox" } } },
           headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["status"]).to eq("pending")
      expect(response.parsed_body["attributes"]).to eq({ "species" => "fox" })
    end

    it "prevents a second character (one per project)" do
      create(:character, project: project)

      post "/api/v1/projects/#{project.id}/character",
           params: { character: { name: "Dup" } }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_state")
    end

    it "requires authentication" do
      post "/api/v1/projects/#{project.id}/character", params: { character: { name: "X" } }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/projects/:project_id/character" do
    it "returns the character to its owner" do
      create(:character, project: project, name: "Rusty")

      get "/api/v1/projects/#{project.id}/character", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["name"]).to eq("Rusty")
    end

    it "hides another user's project (404, no existence leak)" do
      other = create(:project)
      create(:character, project: other)

      get "/api/v1/projects/#{other.id}/character", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/projects/:project_id/character" do
    it "edits a pending character" do
      create(:character, project: project)

      patch "/api/v1/projects/#{project.id}/character",
            params: { character: { name: "Renamed" } }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["name"]).to eq("Renamed")
    end

    it "refuses edits once generation has started" do
      create(:character, :generating, project: project)

      patch "/api/v1/projects/#{project.id}/character",
            params: { character: { name: "Nope" } }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/projects/:project_id/character/generate" do
    it "starts generation and enqueues the pipeline" do
      create(:character, project: project)

      expect do
        post "/api/v1/projects/#{project.id}/character/generate", headers: headers
      end.to have_enqueued_job(GenerateCharacterPromptJob)

      expect(response).to have_http_status(:accepted)
      expect(response.parsed_body["status"]).to eq("generating")
      expect(project.reload).to be_initializing_character
    end
  end

  describe "POST approve / reject" do
    it "approves a character awaiting approval" do
      awaiting_approval_character

      post "/api/v1/projects/#{project.id}/character/approve", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("approved")
      expect(response.parsed_body["locked"]).to be(true)
      expect(project.reload).to be_ready
    end

    it "rejects with feedback" do
      awaiting_approval_character

      post "/api/v1/projects/#{project.id}/character/reject",
           params: { feedback: "too scary" }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("rejected")
      expect(response.parsed_body["rejection_feedback"]).to eq("too scary")
    end
  end

  describe "POST /api/v1/projects/:project_id/character/reset" do
    it "is forbidden for a normal owner" do
      awaiting_approval_character
      post "/api/v1/projects/#{project.id}/character/approve", headers: headers

      post "/api/v1/projects/#{project.id}/character/reset", headers: headers

      expect(response).to have_http_status(:forbidden)
    end

    it "lets an admin reset an approved character" do
      character = awaiting_approval_character
      character.transition_to!(:approved)
      admin = create(:user, :admin)

      post "/api/v1/projects/#{project.id}/character/reset", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("pending")
    end
  end

  describe "GET /api/v1/projects/:project_id/character/image" do
    it "streams the stored image bytes" do
      character = create(:character, project: project)
      png = Base64.decode64(CharacterImageProviders::Fake::PNG_1PX_BASE64)
      Storage.adapter.store(key: "img/1.png", data: png, content_type: "image/png")
      create(:character_image, character: character, storage_key: "img/1.png", mime_type: "image/png")

      get "/api/v1/projects/#{project.id}/character/image", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("image/png")
      expect(response.body.bytesize).to eq(png.bytesize)
    end

    it "returns 404 when no image exists yet" do
      create(:character, project: project)

      get "/api/v1/projects/#{project.id}/character/image", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/projects/:project_id/character" do
    it "deletes a pending character" do
      create(:character, project: project)

      delete "/api/v1/projects/#{project.id}/character", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(project.reload.character).to be_nil
    end

    it "refuses to delete an approved (locked) character" do
      character = awaiting_approval_character
      character.transition_to!(:approved)

      delete "/api/v1/projects/#{project.id}/character", headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
