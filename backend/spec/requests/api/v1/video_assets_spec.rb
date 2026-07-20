require "rails_helper"
require "cgi"

RSpec.describe "Video Assets API", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }
  let(:video) { ready_to_generate_video(user: user) }

  # Drives a full generation + asset pipeline so the video has ready outputs.
  def generate_outputs!
    video.update!(status: :generating)
    perform_enqueued_jobs do
      VideoGenerations::CreateBatch.call(video)
    end
    video
  end

  describe "GET .../assets" do
    it "lists the video's assets with freshly-signed URLs" do
      generate_outputs!

      get "/api/v1/projects/#{video.project_id}/videos/#{video.id}/assets", headers: headers

      expect(response).to have_http_status(:ok)
      assets = response.parsed_body["video_assets"]
      expect(assets.size).to eq(4)
      expect(assets).to all(include("ready" => true))
      expect(assets.first["stream_url"]).to include("/api/v1/downloads?token=")
      expect(assets.first["download_url"]).to be_present
      expect(assets.first["thumbnail_url"]).to be_present
    end

    it "hides another user's video (404, no existence leak)" do
      other = ready_to_generate_video

      get "/api/v1/projects/#{other.project_id}/videos/#{other.id}/assets", headers: headers

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      get "/api/v1/projects/#{video.project_id}/videos/#{video.id}/assets"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET .../assets/archive (download all)" do
    it "streams a ZIP of the outputs" do
      generate_outputs!

      get "/api/v1/projects/#{video.project_id}/videos/#{video.id}/assets/archive", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("application/zip")
      expect(response.body[0, 2]).to eq("PK")
    end

    it "returns 422 when there are no outputs yet" do
      get "/api/v1/projects/#{video.project_id}/videos/#{video.id}/assets/archive", headers: headers
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "public downloads" do
    it "streams the asset video via a signed URL" do
      generate_outputs!
      get "/api/v1/projects/#{video.project_id}/videos/#{video.id}/assets", headers: headers
      url = response.parsed_body["video_assets"].first["download_url"]

      get url

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("video/mp4")
      expect(response.headers["Content-Disposition"]).to include("attachment")
    end

    it "rejects an expired/invalid token" do
      get "/api/v1/downloads", params: { token: "not-a-real-token" }

      expect(response).to have_http_status(:gone)
      expect(response.parsed_body.dig("error", "code")).to eq("link_expired")
    end
  end

  describe "project archive (async)" do
    it "enqueues a build, then serves the archive via a signed URL once ready" do
      generate_outputs!

      # Request a build.
      expect {
        post "/api/v1/projects/#{video.project_id}/download_archive", headers: headers
      }.to have_enqueued_job(BuildProjectDownloadArchiveJob).with(video.project_id)
      expect(response).to have_http_status(:accepted)

      # Before it is built, polling reports pending.
      get "/api/v1/projects/#{video.project_id}/download_archive", headers: headers
      expect(response.parsed_body["status"]).to eq("pending")

      # Build it, then poll returns a signed URL that streams the ZIP.
      perform_enqueued_jobs { BuildProjectDownloadArchiveJob.perform_later(video.project_id) }
      get "/api/v1/projects/#{video.project_id}/download_archive", headers: headers
      expect(response).to have_http_status(:ok)
      url = response.parsed_body["download_url"]
      expect(url).to include("/api/v1/downloads?token=")

      get url
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("application/zip")
      expect(response.body[0, 2]).to eq("PK")
    end
  end
end
