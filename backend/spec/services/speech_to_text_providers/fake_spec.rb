require "rails_helper"

RSpec.describe SpeechToTextProviders::Fake do
  subject(:provider) { described_class.new }

  it "returns a deterministic transcript for the same audio" do
    a = provider.transcribe(audio_data: "hello-bytes", mime_type: "audio/webm", language: "english")
    b = provider.transcribe(audio_data: "hello-bytes", mime_type: "audio/webm", language: "english")

    expect(a.text).to eq(b.text)
    expect(a.provider).to eq("fake")
    expect(a.model).to eq("fake-transcribe-1")
    expect(a.provider_request_id).to eq(b.provider_request_id)
  end

  it "produces a different transcript for different audio" do
    a = provider.transcribe(audio_data: "one", mime_type: "audio/webm")
    b = provider.transcribe(audio_data: "two", mime_type: "audio/webm")

    expect(a.text).not_to eq(b.text)
  end

  it "echoes the requested language" do
    result = provider.transcribe(audio_data: "x", mime_type: "audio/webm", language: "urdu")
    expect(result.language).to eq("urdu")
  end
end
