require "rails_helper"

RSpec.describe "Admin Video Generations API", type: :request do
  include ActiveJob::TestHelper

  let(:admin) { create(:user, :admin) }

  it_behaves_like "an admin-only endpoint", :get, "/api/v1/admin/video_generations"

  describe "GET /api/v1/admin/video_generations" do
    it "lists generations filtered by status (failed-jobs view)" do
      failed = create(:video_generation, :failed)
      create(:video_generation, :completed)

      get "/api/v1/admin/video_generations", params: { status: "failed" }, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["generations"].map { |g| g["id"] }).to contain_exactly(failed.id)
    end
  end

  describe "POST /api/v1/admin/video_generations/:id/retry" do
    it "retries a failed variant and audits it" do
      generation = create(:video_generation, :failed)
      generation.video.update!(status: :generating)

      expect {
        post "/api/v1/admin/video_generations/#{generation.id}/retry", headers: auth_headers(admin)
      }.to change(AuditLog, :count).by(1)
        .and have_enqueued_job(RetryVideoGenerationJob)

      expect(response).to have_http_status(:ok)
      expect(generation.reload).to be_pending
      expect(AuditLog.last.action).to eq("video_generation.retry")
    end
  end

  describe "POST /api/v1/admin/video_generations/:id/cancel" do
    it "cancels the parent video's active batch and audits it" do
      generation = create(:video_generation, :processing)
      generation.video.update!(status: :generating)

      expect {
        post "/api/v1/admin/video_generations/#{generation.id}/cancel", headers: auth_headers(admin)
      }.to change(AuditLog, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(generation.reload).to be_cancelled
      expect(generation.video.reload).to be_cancelled
      expect(AuditLog.last.action).to eq("video_generation.cancel")
    end
  end

  describe "POST /api/v1/admin/video_generations/:id/retry_asset" do
    it "re-runs asset processing for a completed output and audits it" do
      generation = create(:video_generation, :completed)
      create(:video_asset, :ready, video_generation: generation).update!(validation_status: :failed)

      expect {
        post "/api/v1/admin/video_generations/#{generation.id}/retry_asset", headers: auth_headers(admin)
      }.to change(AuditLog, :count).by(1)
        .and have_enqueued_job(DownloadGeneratedVideoJob).with(generation.id)

      expect(response).to have_http_status(:ok)
      expect(AuditLog.last.action).to eq("video_generation.retry_asset")
    end
  end
end
