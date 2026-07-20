require "rails_helper"

RSpec.describe ProcessVideoAudioUploadJob do
  include ActiveJob::TestHelper

  let(:project) { create(:project, :ready) }
  let(:storage_key) { "videos/idea-audio/job.webm" }

  def transcribing_video
    create(:video, :transcribing, project: project, idea_audio_storage_key: storage_key)
  end

  before { Storage.adapter.store(key: storage_key, data: "audio-bytes", content_type: "audio/webm") }

  it "chains to the transcription job when the audio is present" do
    video = transcribing_video

    expect { described_class.perform_now(video.id, video.transcription_id, storage_key, "audio/webm") }
      .to have_enqueued_job(TranscribeVideoIdeaJob)
      .with(video.id, video.transcription_id, storage_key, "audio/webm")
  end

  it "no-ops for a superseded transcription_id" do
    video = transcribing_video

    expect { described_class.perform_now(video.id, "stale", storage_key, "audio/webm") }
      .not_to have_enqueued_job(TranscribeVideoIdeaJob)
    expect(video.reload).to be_transcribing
  end

  it "fails the video (non-retryable) when the stored audio is gone" do
    video = transcribing_video
    Storage.adapter.delete(storage_key)

    described_class.perform_now(video.id, video.transcription_id, storage_key, "audio/webm")

    expect(video.reload).to be_failed
    expect(video.transcription_failure_reason).to be_present
  end
end
