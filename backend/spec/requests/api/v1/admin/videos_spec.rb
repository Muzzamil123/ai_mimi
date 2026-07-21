require "rails_helper"

RSpec.describe "Admin Videos API", type: :request do
  let(:admin) { create(:user, :admin) }

  it_behaves_like "an admin-only endpoint", :get, "/api/v1/admin/videos"

  describe "GET /api/v1/admin/videos" do
    it "lists videos across projects with a status filter" do
      ready = create(:video, :with_idea)
      create(:video)

      get "/api/v1/admin/videos", params: { status: "idea_ready" }, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["videos"].map { |v| v["id"] }).to contain_exactly(ready.id)
    end
  end

  describe "GET /api/v1/admin/videos/:id" do
    it "returns the video with its prompts and generations" do
      video = create(:video, :with_idea)
      create(:prompt, :approved, video: video)

      get "/api/v1/admin/videos/#{video.id}", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["video"]["id"]).to eq(video.id)
      expect(body["prompts"].size).to eq(1)
    end
  end

  describe "POST /api/v1/admin/videos/:id/retry_prompt" do
    it "restarts prompt generation and audits it" do
      video = create(:video, :with_idea)

      expect {
        post "/api/v1/admin/videos/#{video.id}/retry_prompt", headers: auth_headers(admin)
      }.to change(AuditLog, :count).by(1)
        .and have_enqueued_job(GenerateVideoPromptJob)

      expect(response).to have_http_status(:ok)
      expect(video.reload).to be_generating_prompt
      expect(AuditLog.last.action).to eq("prompt.retry_generation")
    end
  end
end
