require "rails_helper"

RSpec.describe Prompts::SavePromptVersion do
  let(:video) { create(:video, :with_idea, status: :prompt_ready) }

  it "saves a manual edit as a new draft version and supersedes the prior draft" do
    prior = create(:prompt, video: video, version: 1, status: :draft)

    prompt = described_class.call(video, content: "My edited prompt", actor: video.project.user)

    expect(prompt).to be_draft
    expect(prompt.version).to eq(2)
    expect(prompt.provider).to eq("manual")
    expect(prompt.content).to eq("My edited prompt")
    expect(prior.reload).to be_superseded
  end

  it "refuses to save before a prompt has been generated" do
    idea_only = create(:video, :with_idea, status: :idea_ready)

    expect { described_class.call(idea_only, content: "x") }
      .to raise_error(Prompts::InvalidState, /Generate a prompt/)
  end

  it "refuses blank content" do
    create(:prompt, video: video, version: 1, status: :draft)

    expect { described_class.call(video, content: "   ") }
      .to raise_error(Prompts::InvalidState, /cannot be blank/)
  end

  it "refuses to save while the video is mid-generation (never strands it)" do
    create(:prompt, :generating, video: video, version: 1, content: nil)
    video.update!(status: :generating_prompt)

    expect { described_class.call(video, content: "new text") }
      .to raise_error(Prompts::InvalidState, /Generate a prompt/)
    expect(video.reload).to be_generating_prompt
  end
end
