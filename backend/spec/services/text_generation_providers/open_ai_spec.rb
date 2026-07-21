require "rails_helper"

RSpec.describe TextGenerationProviders::OpenAI do
  subject(:provider) { described_class.new }

  let(:endpoint) { "https://api.openai.com/v1/chat/completions" }
  let(:context) do
    Prompts::Context.new(
      character_description: "Rusty, a cheerful fox",
      idea: "wave hello",
      language: "english",
      tone: "playful",
      duration_seconds: 15,
      target_platforms: [ "instagram_reels" ]
    )
  end

  around do |example|
    original = ENV["OPENAI_API_KEY"]
    ENV["OPENAI_API_KEY"] = "sk-test"
    example.run
    ENV["OPENAI_API_KEY"] = original
  end

  it "returns the generated prompt with token/cost usage" do
    body = {
      id: "chatcmpl-1",
      model: "gpt-4o-mini",
      choices: [ { message: { content: "A 15s vertical clip of the fox waving." } } ],
      usage: { prompt_tokens: 120, completion_tokens: 200, total_tokens: 320 }
    }.to_json

    stub_request(:post, endpoint)
      .with(headers: { "Authorization" => "Bearer sk-test" })
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    result = provider.generate_video_prompt(idea: "wave hello", context: context)

    expect(result.content).to eq("A 15s vertical clip of the fox waving.")
    expect(result.provider).to eq("openai")
    expect(result.provider_request_id).to eq("chatcmpl-1")
    expect(result.input_tokens).to eq(120)
    expect(result.output_tokens).to eq(200)
    expect(result.estimated_cost).to be > 0
  end

  it "sends the character description and idea in the request" do
    stub = stub_request(:post, endpoint)
      .with { |req| req.body.include?("Rusty") && req.body.include?("wave hello") }
      .to_return(status: 200, body: { choices: [ { message: { content: "ok" } } ] }.to_json)

    provider.generate_video_prompt(idea: "wave hello", context: context)

    expect(stub).to have_been_requested
  end

  it "raises a retryable error on a 429" do
    stub_request(:post, endpoint).to_return(status: 429, body: { error: { message: "slow" } }.to_json)

    expect { provider.generate_video_prompt(idea: "x", context: context) }
      .to raise_error(TextGenerationProviders::Error) { |e| expect(e.retryable).to be(true) }
  end

  it "raises a non-retryable error when the key is missing" do
    ENV["OPENAI_API_KEY"] = ""

    expect { provider.generate_video_prompt(idea: "x", context: context) }
      .to raise_error(TextGenerationProviders::Error, /API key is not configured/)
  end
end
