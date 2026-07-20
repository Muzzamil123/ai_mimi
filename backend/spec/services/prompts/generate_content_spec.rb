require "rails_helper"

RSpec.describe Prompts::GenerateContent do
  let(:video) { create(:video, :with_idea, status: :generating_prompt) }
  let(:prompt) { create(:prompt, :generating, video: video, content: nil) }

  it "fills content, records usage, and advances prompt + video with the local provider" do
    described_class.call(prompt)

    prompt.reload
    expect(prompt).to be_draft
    expect(prompt.content).to be_present
    expect(prompt.provider).to eq("local")
    expect(prompt.input_tokens).to be > 0
    expect(prompt.output_tokens).to be > 0
    expect(video.reload).to be_prompt_ready
  end

  it "grounds the provider call in the built context (idea + character description)" do
    provider = instance_double(TextGenerationProviders::Local)
    captured = {}
    allow(provider).to receive(:generate_video_prompt) do |idea:, context:, **|
      captured[:idea] = idea
      captured[:context] = context
      TextGenerationProviders::Result.new(content: "generated", provider: "local", model: "m")
    end

    described_class.call(prompt, provider: provider)

    expect(captured[:idea]).to eq(video.idea_source)
    expect(captured[:context]).to be_a(Prompts::Context)
    expect(captured[:context].duration_seconds).to eq(15)
    expect(prompt.reload.content).to eq("generated")
  end
end
