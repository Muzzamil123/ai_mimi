require "rails_helper"

RSpec.describe "Video Generations API", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }
  let(:video) { ready_to_generate_video(user: user) }

  def base_path(v = video)
    "/api/v1/projects/#{v.project_id}/videos/#{v.id}/generations"
  end

  describe "POST .../generations" do
    it "starts generation and creates exactly four records" do
      expect {
        perform_enqueued_jobs { post base_path, headers: headers }
      }.to change { video.video_generations.count }.from(0).to(4)

      expect(response).to have_http_status(:accepted)
      expect(video.reload).to be_completed # fake provider completes all four
    end

    it "requires an approved prompt" do
      video.update!(active_prompt_id: nil)

      post base_path, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_state")
    end

    it "requires an approved character" do
      video.project.update!(active_character_id: nil)

      post base_path, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "prevents a duplicate request while in progress" do
      post base_path, headers: headers # video -> queued, batch enqueued (not run)

      post base_path, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "messages").join).to match(/already in progress/)
    end

    it "requires authentication" do
      post base_path
      expect(response).to have_http_status(:unauthorized)
    end

    it "hides another user's video (404)" do
      other = ready_to_generate_video
      post base_path(other), headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET .../generations" do
    it "lists the four outputs after generation" do
      perform_enqueued_jobs { post base_path, headers: headers }

      get base_path, headers: headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body["video_generations"]
      expect(body.size).to eq(4)
      expect(body.map { |g| g["aspect_ratio"] }.tally).to eq("3:4" => 2, "9:16" => 2)
      expect(body).to all(include("status" => "completed"))
    end
  end

  describe "retry + cancel" do
    it "retries a failed output" do
      perform_enqueued_jobs { post base_path, headers: headers }
      failed = video.video_generations.first
      failed.update!(status: :failed, error_code: "boom")
      video.update!(status: :partially_completed)

      post "#{base_path}/#{failed.id}/retry", headers: headers

      expect(response).to have_http_status(:accepted)
      expect(failed.reload).to be_pending
    end

    it "cancels an in-progress batch" do
      post base_path, headers: headers # queued, batch not run
      # Simulate an in-flight batch.
      VideoGenerations::CreateBatch.call(video.reload)

      post "#{base_path}/cancel", headers: headers

      expect(response).to have_http_status(:ok)
      expect(video.reload).to be_cancelled
    end
  end
end
