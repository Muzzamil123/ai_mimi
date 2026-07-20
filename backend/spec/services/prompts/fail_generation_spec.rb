require "rails_helper"

RSpec.describe Prompts::FailGeneration do
  let(:video) { create(:video, :with_idea, status: :generating_prompt) }

  it "marks the prompt and video failed with the reason" do
    prompt = create(:prompt, :generating, video: video, content: nil)

    described_class.call(prompt, generation_id: prompt.generation_id, reason: "boom")

    expect(prompt.reload).to be_failed
    expect(prompt.failure_reason).to eq("boom")
    expect(video.reload).to be_failed
  end

  it "is a no-op for a superseded generation_id" do
    prompt = create(:prompt, :generating, video: video, content: nil)

    described_class.call(prompt, generation_id: "stale", reason: "late")

    expect(prompt.reload).to be_generating
    expect(video.reload).to be_generating_prompt
  end
end
