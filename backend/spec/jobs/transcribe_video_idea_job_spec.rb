require "rails_helper"

RSpec.describe TranscribeVideoIdeaJob do
  include ActiveJob::TestHelper

  let(:project) { create(:project, :ready) }
  let(:storage_key) { "videos/idea-audio/job.webm" }

  def transcribing_video
    create(:video, :transcribing, project: project, idea_audio_storage_key: storage_key)
  end

  before { Storage.adapter.store(key: storage_key, data: "audio-bytes", content_type: "audio/webm") }

  it "transcribes with the fake provider and moves the video to idea_ready" do
    video = transcribing_video

    described_class.perform_now(video.id, video.transcription_id, storage_key, "audio/webm")

    video.reload
    expect(video).to be_idea_ready
    expect(video.transcript).to be_present
  end

  it "no-ops for a superseded transcription_id" do
    video = transcribing_video

    described_class.perform_now(video.id, "stale", storage_key, "audio/webm")

    expect(video.reload).to be_transcribing
    expect(video.transcript).to be_nil
  end

  it "retries on a transient provider error, then fails after exhaustion" do
    video = transcribing_video
    allow(SpeechToTextProviders).to receive(:build).and_return(
      instance_double(SpeechToTextProviders::Fake).tap do |p|
        allow(p).to receive(:transcribe).and_raise(SpeechToTextProviders::Error.new("timeout", retryable: true))
      end
    )

    perform_enqueued_jobs do
      described_class.perform_later(video.id, video.transcription_id, storage_key, "audio/webm")
    end

    expect(video.reload).to be_failed
    expect(video.transcription_failure_reason).to match(/after retries/)
  end

  it "fails immediately (no retry) on a permanent provider error" do
    video = transcribing_video
    allow(SpeechToTextProviders).to receive(:build).and_return(
      instance_double(SpeechToTextProviders::Fake).tap do |p|
        allow(p).to receive(:transcribe).and_raise(SpeechToTextProviders::Error.new("bad audio", retryable: false))
      end
    )

    described_class.perform_now(video.id, video.transcription_id, storage_key, "audio/webm")

    expect(video.reload).to be_failed
    expect(video.transcription_failure_reason).to eq("bad audio")
  end
end
