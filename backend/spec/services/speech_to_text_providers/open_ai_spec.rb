require "rails_helper"

RSpec.describe SpeechToTextProviders::OpenAI do
  subject(:provider) { described_class.new }

  let(:endpoint) { "https://api.openai.com/v1/audio/transcriptions" }

  around do |example|
    original = ENV["OPENAI_API_KEY"]
    ENV["OPENAI_API_KEY"] = "sk-test"
    example.run
    ENV["OPENAI_API_KEY"] = original
  end

  it "returns the transcript, language, and cost metadata" do
    body = { text: "Hello from the mascot", model: "whisper-1", duration: 30 }.to_json
    stub_request(:post, endpoint)
      .with(headers: { "Authorization" => "Bearer sk-test" })
      .to_return(
        status: 200,
        body: body,
        headers: { "Content-Type" => "application/json", "x-request-id" => "req-123" }
      )

    result = provider.transcribe(audio_data: "audio", mime_type: "audio/webm", language: "english")

    expect(result.text).to eq("Hello from the mascot")
    expect(result.provider).to eq("openai")
    expect(result.model).to eq("whisper-1")
    expect(result.provider_request_id).to eq("req-123")
    expect(result.duration_seconds).to eq(30.0)
    expect(result.estimated_cost).to be > 0
  end

  it "sends the language hint mapped to ISO-639-1" do
    stub = stub_request(:post, endpoint)
      .with { |req| req.body.include?("name=\"language\"") && req.body.include?("ur") }
      .to_return(status: 200, body: { text: "salaam" }.to_json)

    provider.transcribe(audio_data: "audio", mime_type: "audio/webm", language: "roman_urdu")

    expect(stub).to have_been_requested
  end

  it "raises a retryable error on a 429 response" do
    stub_request(:post, endpoint).to_return(status: 429, body: { error: { message: "slow down" } }.to_json)

    expect { provider.transcribe(audio_data: "audio", mime_type: "audio/webm") }
      .to raise_error(SpeechToTextProviders::Error) { |e| expect(e.retryable).to be(true) }
  end

  it "raises a non-retryable error on a 400 response" do
    stub_request(:post, endpoint).to_return(status: 400, body: { error: { message: "bad file" } }.to_json)

    expect { provider.transcribe(audio_data: "audio", mime_type: "audio/webm") }
      .to raise_error(SpeechToTextProviders::Error) { |e| expect(e.retryable).to be(false) }
  end

  it "raises when the API key is not configured" do
    ENV["OPENAI_API_KEY"] = ""

    expect { provider.transcribe(audio_data: "audio", mime_type: "audio/webm") }
      .to raise_error(SpeechToTextProviders::Error, /OPENAI_API_KEY/)
  end

  it "raises without calling the API when the audio is empty" do
    expect { provider.transcribe(audio_data: "", mime_type: "audio/webm") }
      .to raise_error(SpeechToTextProviders::Error, /empty/)
    expect(a_request(:post, endpoint)).not_to have_been_made
  end
end

RSpec.describe SpeechToTextProviders do
  describe ".build" do
    it "builds the fake provider by default off-production" do
      expect(described_class.build(name: "fake")).to be_a(SpeechToTextProviders::Fake)
    end

    it "builds the OpenAI provider when selected" do
      expect(described_class.build(name: "openai")).to be_a(SpeechToTextProviders::OpenAI)
    end

    it "raises on an unknown provider" do
      expect { described_class.build(name: "nope") }.to raise_error(SpeechToTextProviders::Error)
    end
  end
end
