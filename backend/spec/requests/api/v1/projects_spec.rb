require "rails_helper"

RSpec.describe "Projects API", type: :request do
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe "GET /api/v1/projects" do
    it "returns only the current user's projects with pagination meta" do
      create_list(:project, 3, user: user)
      create(:project) # another user's

      get "/api/v1/projects", headers: headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["projects"].size).to eq(3)
      expect(body["meta"]).to include("page", "per_page", "total_count", "total_pages")
      expect(body["meta"]["total_count"]).to eq(3)
    end

    it "filters by status and searches by name" do
      create(:project, user: user, name: "Baby Shark")
      create(:project, user: user, name: "Puppy Tales", status: :ready)

      get "/api/v1/projects", params: { q: "shark" }, headers: headers
      expect(response.parsed_body["projects"].map { |p| p["name"] }).to eq([ "Baby Shark" ])

      get "/api/v1/projects", params: { status: "ready" }, headers: headers
      expect(response.parsed_body["projects"].map { |p| p["name"] }).to eq([ "Puppy Tales" ])
    end

    it "paginates with page/per_page" do
      create_list(:project, 5, user: user)

      get "/api/v1/projects", params: { per_page: 2, page: 1 }, headers: headers

      expect(response.parsed_body["projects"].size).to eq(2)
      expect(response.parsed_body["meta"]["total_pages"]).to eq(3)
    end

    it "requires authentication" do
      get "/api/v1/projects"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/projects" do
    it "creates a draft project owned by the caller" do
      expect do
        post "/api/v1/projects",
             params: { project: { name: "New One", default_language: "urdu", target_platforms: [ "tiktok" ] } },
             headers: headers, as: :json
      end.to change(Project, :count).by(1)

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["status"]).to eq("draft")
      expect(body["slug"]).to eq("new-one")
      expect(body["user_id"]).to eq(user.id)
    end

    it "rejects invalid params" do
      post "/api/v1/projects", params: { project: { name: "" } }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]["code"]).to eq("validation_failed")
    end
  end

  describe "GET /api/v1/projects/:id" do
    it "shows an owned project including status history" do
      project = Projects::CreateProject.call(user, { name: "Mine" })
      get "/api/v1/projects/#{project.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status_changes"]).to be_present
    end

    it "returns 404 for another user's project (no existence leak)" do
      other = create(:project)
      get "/api/v1/projects/#{other.id}", headers: headers
      expect(response).to have_http_status(:not_found)
    end

    it "lets an admin view any project" do
      admin = create(:user, :admin)
      other = create(:project)
      get "/api/v1/projects/#{other.id}", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /api/v1/projects/:id" do
    it "updates a draft project" do
      project = create(:project, user: user)
      patch "/api/v1/projects/#{project.id}",
            params: { project: { name: "Renamed" } }, headers: headers, as: :json

      expect(response).to have_http_status(:ok)
      expect(project.reload.name).to eq("Renamed")
    end

    it "refuses to edit a non-draft project" do
      project = create(:project, user: user, status: :ready)
      patch "/api/v1/projects/#{project.id}",
            params: { project: { name: "Nope" } }, headers: headers, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]["code"]).to eq("invalid_transition")
    end
  end

  describe "DELETE /api/v1/projects/:id" do
    it "deletes a draft project" do
      project = create(:project, user: user)
      delete "/api/v1/projects/#{project.id}", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(Project.exists?(project.id)).to be(false)
    end

    it "refuses to delete a non-draft project" do
      project = create(:project, user: user, status: :ready)
      delete "/api/v1/projects/#{project.id}", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "archive / restore" do
    it "archives then restores a project" do
      project = create(:project, user: user)

      post "/api/v1/projects/#{project.id}/archive", headers: headers
      expect(response).to have_http_status(:ok)
      expect(project.reload).to be_archived

      post "/api/v1/projects/#{project.id}/restore", headers: headers
      expect(response).to have_http_status(:ok)
      expect(project.reload).to be_draft
    end

    it "returns 422 when restoring a project that is not archived" do
      project = create(:project, user: user)
      post "/api/v1/projects/#{project.id}/restore", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]["code"]).to eq("invalid_transition")
    end
  end

  describe "cross-user access" do
    let(:others_project) { create(:project) }

    it "returns 404 when mutating another user's project" do
      patch "/api/v1/projects/#{others_project.id}",
            params: { project: { name: "x" } }, headers: headers, as: :json
      expect(response).to have_http_status(:not_found)

      delete "/api/v1/projects/#{others_project.id}", headers: headers
      expect(response).to have_http_status(:not_found)

      post "/api/v1/projects/#{others_project.id}/archive", headers: headers
      expect(response).to have_http_status(:not_found)

      post "/api/v1/projects/#{others_project.id}/restore", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "mass-assignment protection" do
    it "ignores non-permitted attributes on create" do
      post "/api/v1/projects",
           params: { project: { name: "Sneaky", status: "ready", user_id: 999_999,
                                slug: "hacked", active_character_id: 5,
                                archived_at: Time.current.iso8601 } },
           headers: headers, as: :json

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["status"]).to eq("draft")
      expect(body["slug"]).to eq("sneaky")
      expect(body["user_id"]).to eq(user.id)
      expect(body["active_character_id"]).to be_nil
      expect(body["archived_at"]).to be_nil
    end
  end

  describe "pagination bounds" do
    it "clamps per_page to the maximum and floors page at 1" do
      get "/api/v1/projects", params: { per_page: 9999, page: 0 }, headers: headers
      meta = response.parsed_body["meta"]
      expect(meta["per_page"]).to eq(100)
      expect(meta["page"]).to eq(1)
    end
  end
end
