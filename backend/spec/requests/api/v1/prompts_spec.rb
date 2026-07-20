require "rails_helper"

RSpec.describe "Prompts API", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }
  let(:project) { create(:project, :ready, user: user) }
  let(:video) { create(:video, :with_idea, project: project) }

  def base_path(v = video)
    "/api/v1/projects/#{project.id}/videos/#{v.id}/prompts"
  end

  describe "POST .../prompts/generate" do
    it "starts async generation and returns the generating prompt" do
      expect {
        post "#{base_path}/generate", headers: headers
      }.to have_enqueued_job(GenerateVideoPromptJob)

      expect(response).to have_http_status(:accepted)
      expect(response.parsed_body["status"]).to eq("generating")
      expect(response.parsed_body["version"]).to eq(1)
    end

    it "generates end-to-end with the local provider" do
      perform_enqueued_jobs { post "#{base_path}/generate", headers: headers }

      video.reload
      expect(video).to be_prompt_ready
      expect(video.current_prompt).to be_draft
      expect(video.current_prompt.content).to be_present
      expect(video.current_prompt.input_tokens).to be > 0
    end

    it "increments the version on regeneration" do
      create(:prompt, video: video, version: 1, status: :draft)
      video.update!(status: :prompt_ready)

      post "#{base_path}/generate", headers: headers

      expect(response.parsed_body["version"]).to eq(2)
    end

    it "refuses to generate without an idea" do
      empty = create(:video, project: project, idea_text: nil, transcript: nil, status: :idea_ready)

      post "#{base_path(empty)}/generate", headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_state")
    end

    it "requires authentication" do
      post "#{base_path}/generate"
      expect(response).to have_http_status(:unauthorized)
    end

    it "hides another user's video (404)" do
      other = create(:video, :with_idea, project: create(:project, :ready))
      post "#{base_path(other)}/generate", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET .../prompts (history)" do
    it "lists versions newest-first with pagination meta" do
      create(:prompt, video: video, version: 1, status: :superseded)
      create(:prompt, video: video, version: 2, status: :draft)

      get base_path, headers: headers

      expect(response).to have_http_status(:ok)
      versions = response.parsed_body["prompts"].map { |p| p["version"] }
      expect(versions).to eq([ 2, 1 ])
      expect(response.parsed_body["meta"]).to include("total_count" => 2)
    end
  end

  describe "POST .../prompts (manual save)" do
    it "saves a manual edit as a new draft version" do
      create(:prompt, video: video, version: 1, status: :draft)
      video.update!(status: :prompt_ready)

      post base_path, params: { prompt: { content: "My edited prompt" } }, headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["version"]).to eq(2)
      expect(response.parsed_body["provider"]).to eq("manual")
      expect(response.parsed_body["content"]).to eq("My edited prompt")
    end
  end

  describe "POST .../prompts/:id/approve" do
    it "approves a draft and marks it active" do
      video.update!(status: :prompt_ready)
      prompt = create(:prompt, video: video, version: 1, status: :draft)

      post "#{base_path}/#{prompt.id}/approve", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("approved")
      expect(response.parsed_body["active"]).to be(true)
      expect(video.reload.active_prompt_id).to eq(prompt.id)
    end

    it "forbids a non-owner (404, no existence leak)" do
      video.update!(status: :prompt_ready)
      prompt = create(:prompt, video: video, version: 1, status: :draft)
      other_headers = auth_headers(create(:user))

      post "#{base_path}/#{prompt.id}/approve", headers: other_headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
