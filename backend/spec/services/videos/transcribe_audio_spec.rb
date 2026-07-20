require "rails_helper"

RSpec.describe Videos::TranscribeAudio do
  let(:project) { create(:project, :ready) }
  let(:storage_key) { "videos/idea-audio/test.webm" }

  before { Storage.adapter.store(key: storage_key, data: "audio-bytes", content_type: "audio/webm") }

  def transcribing_video
    create(:video, :transcribing, project: project, idea_audio_storage_key: storage_key)
  end

  it "transcribes, persists the transcript and metadata, and moves to idea_ready" do
    video = transcribing_video

    described_class.call(video, storage_key: storage_key, mime_type: "audio/webm")

    video.reload
    expect(video).to be_idea_ready
    expect(video.transcript).to be_present
    expect(video.transcription_provider).to eq("fake")
    expect(video.transcription_provider_model).to eq("fake-transcribe-1")
  end

  it "passes the audio, language, and mime type to the provider" do
    video = transcribing_video
    provider = instance_double(SpeechToTextProviders::Fake)
    result = SpeechToTextProviders::Result.new(text: "hello", provider: "fake", model: "m")
    expect(provider).to receive(:transcribe)
      .with(audio_data: "audio-bytes", mime_type: "audio/webm", language: "english", filename: "test.webm")
      .and_return(result)

    described_class.call(video, storage_key: storage_key, mime_type: "audio/webm", provider: provider)

    expect(video.reload.transcript).to eq("hello")
  end

  it "raises when the stored audio is missing" do
    video = transcribing_video
    Storage.adapter.delete(storage_key)

    expect { described_class.call(video, storage_key: storage_key, mime_type: "audio/webm") }
      .to raise_error(Storage::Error, /missing from storage/)
  end
end
