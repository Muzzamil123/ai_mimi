require "rails_helper"
require "base64"

RSpec.describe CharacterImageProviders::Gemini do
  subject(:provider) { described_class.new }

  let(:endpoint) do
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent"
  end

  around do |example|
    original = ENV["GEMINI_API_KEY"]
    ENV["GEMINI_API_KEY"] = "test-key"
    example.run
    ENV["GEMINI_API_KEY"] = original
  end

  def success_body
    {
      candidates: [ { content: { parts: [ { inlineData: { mimeType: "image/png", data: Base64.strict_encode64("PNGDATA") } } ] } } ],
      responseId: "resp-123",
      modelVersion: "gemini-2.5-flash-image-001"
    }.to_json
  end

  it "sends the API key header and returns a normalized result" do
    stub = stub_request(:post, endpoint)
      .with(headers: { "x-goog-api-key" => "test-key" })
      .to_return(status: 200, body: success_body, headers: { "Content-Type" => "application/json" })

    result = provider.generate(prompt: "a fox", options: { style_preferences: { palette: "warm" } })

    expect(stub).to have_been_requested
    expect(result.image_data).to eq("PNGDATA")
    expect(result.mime_type).to eq("image/png")
    expect(result.provider).to eq("gemini")
    expect(result.model).to eq("gemini-2.5-flash-image-001")
    expect(result.provider_request_id).to eq("resp-123")
    expect(result.estimated_cost).to be > 0
  end

  it "raises a non-retryable error on a 400 response" do
    stub_request(:post, endpoint)
      .to_return(status: 400, body: { error: { message: "bad prompt" } }.to_json)

    expect { provider.generate(prompt: "x") }
      .to raise_error(CharacterImageProviders::Error) { |e| expect(e.retryable).to be(false) }
  end

  it "raises a retryable error on a 500 response" do
    stub_request(:post, endpoint).to_return(status: 500, body: "{}")

    expect { provider.generate(prompt: "x") }
      .to raise_error(CharacterImageProviders::Error) { |e| expect(e.retryable).to be(true) }
  end

  it "raises a TimeoutError when the request times out" do
    stub_request(:post, endpoint).to_timeout

    expect { provider.generate(prompt: "x") }
      .to raise_error(CharacterImageProviders::TimeoutError) { |e| expect(e.retryable).to be(true) }
  end

  it "raises a retryable error when the returned image data is empty" do
    body = { candidates: [ { content: { parts: [ { inlineData: { mimeType: "image/png", data: "" } } ] } } ] }.to_json
    stub_request(:post, endpoint).to_return(status: 200, body: body)

    expect { provider.generate(prompt: "x") }
      .to raise_error(CharacterImageProviders::Error, /empty image/)
  end

  it "raises a non-retryable error when the response contains no image" do
    stub_request(:post, endpoint)
      .to_return(status: 200, body: { candidates: [ { content: { parts: [] } } ] }.to_json)

    expect { provider.generate(prompt: "x") }
      .to raise_error(CharacterImageProviders::Error, /no image/)
  end

  it "raises when the API key is not configured" do
    ENV["GEMINI_API_KEY"] = ""

    expect { provider.generate(prompt: "x") }
      .to raise_error(CharacterImageProviders::Error, /GEMINI_API_KEY/)
  end
end
