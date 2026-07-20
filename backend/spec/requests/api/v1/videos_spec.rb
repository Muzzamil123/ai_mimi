require "rails_helper"

RSpec.describe "Videos API", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }
  let(:project) { create(:project, :ready, user: user) }

  # A minimal multipart upload for the audio endpoint.
  def audio_upload(content_type: "audio/webm", bytes: "RIFFfakeaudio")
    Rack::Test::UploadedFile.new(StringIO.new(bytes), content_type, original_filename: "idea.webm")
  end

  describe "POST /api/v1/projects/:project_id/videos" do
    it "creates a draft video under a ready project" do
      post "/api/v1/projects/#{project.id}/videos",
           params: { video: { title: "Launch teaser" } }, headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["status"]).to eq("draft")
      expect(response.parsed_body["title"]).to eq("Launch teaser")
    end

    it "allows multiple videos per project" do
      post "/api/v1/projects/#{project.id}/videos", params: { video: { title: "One" } }, headers: headers
      post "/api/v1/projects/#{project.id}/videos", params: { video: { title: "Two" } }, headers: headers

      expect(project.videos.count).to eq(2)
    end

    it "forbids creating a video before the character is approved" do
      draft_project = create(:project, status: :draft, user: user)

      post "/api/v1/projects/#{draft_project.id}/videos",
           params: { video: { title: "Too soon" } }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_state")
    end

    it "rejects a non-15-second duration" do
      post "/api/v1/projects/#{project.id}/videos",
           params: { video: { title: "Long", duration_seconds: 60 } }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("validation_failed")
    end

    it "requires authentication" do
      post "/api/v1/projects/#{project.id}/videos", params: { video: { title: "X" } }

      expect(response).to have_http_status(:unauthorized)
    end

    it "hides another user's project (404, no existence leak)" do
      other = create(:project, :ready)

      post "/api/v1/projects/#{other.id}/videos", params: { video: { title: "X" } }, headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/projects/:project_id/videos" do
    it "lists the project's videos with pagination meta" do
      create_list(:video, 2, project: project)

      get "/api/v1/projects/#{project.id}/videos", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["videos"].size).to eq(2)
      expect(response.parsed_body["meta"]).to include("total_count" => 2)
    end

    it "filters by search query" do
      create(:video, project: project, title: "Launch teaser")
      create(:video, project: project, title: "Unrelated")

      get "/api/v1/projects/#{project.id}/videos", params: { q: "launch" }, headers: headers

      expect(response.parsed_body["videos"].map { |v| v["title"] }).to eq([ "Launch teaser" ])
    end
  end

  describe "GET /api/v1/projects/:project_id/videos/:id" do
    it "returns the video with status history to its owner" do
      video = create(:video, :with_idea, project: project)

      get "/api/v1/projects/#{project.id}/videos/#{video.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["idea_present"]).to be(true)
      expect(response.parsed_body).to have_key("status_changes")
    end

    it "hides another user's video (404)" do
      other_video = create(:video, project: create(:project, :ready))

      get "/api/v1/projects/#{project.id}/videos/#{other_video.id}", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/projects/:project_id/videos/:id" do
    it "sets a typed idea and advances to idea_ready" do
      video = create(:video, project: project)

      patch "/api/v1/projects/#{project.id}/videos/#{video.id}",
            params: { video: { idea_text: "A fun clip" } }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("idea_ready")
      expect(response.parsed_body["idea_text"]).to eq("A fun clip")
    end

    it "edits the transcript" do
      video = create(:video, :transcribed, project: project)

      patch "/api/v1/projects/#{project.id}/videos/#{video.id}",
            params: { video: { transcript: "Edited" } }, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["transcript"]).to eq("Edited")
    end
  end

  describe "DELETE /api/v1/projects/:project_id/videos/:id" do
    it "deletes a draft video" do
      video = create(:video, project: project)

      delete "/api/v1/projects/#{project.id}/videos/#{video.id}", headers: headers

      expect(response).to have_http_status(:no_content)
      expect(Video.exists?(video.id)).to be(false)
    end

    it "refuses to delete a non-draft video" do
      video = create(:video, :with_idea, project: project)

      delete "/api/v1/projects/#{project.id}/videos/#{video.id}", headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "POST /api/v1/projects/:project_id/videos/:id/audio" do
    it "accepts an audio upload and starts transcription" do
      video = create(:video, project: project)

      expect {
        post "/api/v1/projects/#{project.id}/videos/#{video.id}/audio",
             params: { audio: audio_upload }, headers: headers
      }.to have_enqueued_job(ProcessVideoAudioUploadJob)

      expect(response).to have_http_status(:accepted)
      expect(response.parsed_body["status"]).to eq("transcribing")
      expect(response.parsed_body["has_audio"]).to be(true)
    end

    it "rejects an unsupported audio type" do
      video = create(:video, project: project)

      post "/api/v1/projects/#{project.id}/videos/#{video.id}/audio",
           params: { audio: audio_upload(content_type: "application/pdf") }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_audio")
    end

    it "transcribes end-to-end with the fake provider" do
      video = create(:video, project: project)

      perform_enqueued_jobs do
        post "/api/v1/projects/#{project.id}/videos/#{video.id}/audio",
             params: { audio: audio_upload }, headers: headers
      end

      video.reload
      expect(video).to be_idea_ready
      expect(video.transcript).to be_present
    end
  end
end
