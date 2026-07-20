require "rails_helper"

RSpec.describe TextGenerationProviders::Local do
  subject(:provider) { described_class.new }

  let(:video) { build_stubbed(:video, :with_idea, idea_text: "wave hello", tone: "playful") }
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

  it "returns a structured prompt covering the required directions and usage" do
    result = provider.generate_video_prompt(idea: "wave hello", context: context)

    expect(result.content).to include("Camera direction", "Character movement", "Audio style")
    expect(result.content).to include("attached approved character image")
    expect(result.provider).to eq("local")
    expect(result.input_tokens).to be > 0
    expect(result.output_tokens).to be > 0
    expect(result.estimated_cost).to eq(0)
  end

  it "is deterministic for the same context" do
    a = provider.generate_video_prompt(idea: "wave hello", context: context)
    b = provider.generate_video_prompt(idea: "wave hello", context: context)
    expect(a.provider_request_id).to eq(b.provider_request_id)
  end
end

RSpec.describe TextGenerationProviders do
  describe ".build" do
    it "builds the local provider off-production" do
      expect(described_class.build(name: "local")).to be_a(TextGenerationProviders::Local)
    end

    it "builds the OpenAI provider when selected" do
      expect(described_class.build(name: "openai")).to be_a(TextGenerationProviders::OpenAI)
    end

    it "raises on an unknown provider" do
      expect { described_class.build(name: "nope") }.to raise_error(TextGenerationProviders::Error)
    end
  end
end
