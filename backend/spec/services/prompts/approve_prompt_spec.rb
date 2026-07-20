require "rails_helper"

RSpec.describe Prompts::ApprovePrompt do
  let(:video) { create(:video, :with_idea, status: :prompt_ready) }

  it "approves a draft, supersedes others, and sets the active prompt" do
    old = create(:prompt, video: video, version: 1, status: :draft)
    current = create(:prompt, video: video, version: 2, status: :draft)

    described_class.call(current, actor: video.project.user)

    expect(current.reload).to be_approved
    expect(old.reload).to be_superseded
    expect(video.reload.active_prompt_id).to eq(current.id)
  end

  it "supersedes a previously approved version when a new one is approved" do
    first = create(:prompt, :approved, video: video, version: 1)
    video.update!(active_prompt_id: first.id)
    second = create(:prompt, video: video, version: 2, status: :draft)

    described_class.call(second)

    expect(first.reload).to be_superseded
    expect(second.reload).to be_approved
    expect(video.reload.active_prompt_id).to eq(second.id)
  end

  it "refuses to approve a non-draft prompt" do
    prompt = create(:prompt, :generating, video: video, content: nil)

    expect { described_class.call(prompt) }
      .to raise_error(Prompts::InvalidState, /Only a draft/)
  end

  it "refuses to approve while the video is mid-generation (never strands it)" do
    # Models a concurrent regenerate winning the lock first: the video is back in
    # generating_prompt with an older draft still in memory.
    prompt = create(:prompt, video: video, version: 1, status: :draft)
    video.update!(status: :generating_prompt)

    expect { described_class.call(prompt) }
      .to raise_error(Prompts::InvalidState, /not ready/)
    expect(video.reload).to be_generating_prompt
  end

  it "is a no-op when re-approving the already-active prompt" do
    prompt = create(:prompt, :approved, video: video, version: 1)
    video.update!(active_prompt_id: prompt.id)

    expect { described_class.call(prompt) }.not_to raise_error
    expect(prompt.reload).to be_approved
  end
end
