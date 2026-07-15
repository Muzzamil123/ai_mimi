require "rails_helper"

RSpec.describe CharacterPromptProviders::OpenAI do
  subject(:provider) { described_class.new }

  let(:character) { build(:character, name: "Rusty") }
  let(:endpoint) { "https://api.openai.com/v1/chat/completions" }

  around do |example|
    original = ENV["OPENAI_API_KEY"]
    ENV["OPENAI_API_KEY"] = "sk-test"
    example.run
    ENV["OPENAI_API_KEY"] = original
  end

  it "returns the generated prompt and token/cost metadata" do
    body = {
      id: "chatcmpl-1",
      model: "gpt-4o-mini",
      choices: [ { message: { content: "A bold fox mascot, front facing" } } ],
      usage: { prompt_tokens: 40, completion_tokens: 60, total_tokens: 100 }
    }.to_json

    stub_request(:post, endpoint)
      .with(headers: { "Authorization" => "Bearer sk-test" })
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })

    result = provider.generate(character: character)

    expect(result.prompt).to eq("A bold fox mascot, front facing")
    expect(result.provider).to eq("openai")
    expect(result.provider_request_id).to eq("chatcmpl-1")
    expect(result.prompt_tokens).to eq(40)
    expect(result.estimated_cost).to be > 0
  end

  it "raises a retryable error on a 429 response" do
    stub_request(:post, endpoint).to_return(status: 429, body: { error: { message: "slow down" } }.to_json)

    expect { provider.generate(character: character) }
      .to raise_error(CharacterPromptProviders::Error) { |e| expect(e.retryable).to be(true) }
  end

  it "raises when the API key is not configured" do
    ENV["OPENAI_API_KEY"] = ""

    expect { provider.generate(character: character) }
      .to raise_error(CharacterPromptProviders::Error, /OPENAI_API_KEY/)
  end
end
