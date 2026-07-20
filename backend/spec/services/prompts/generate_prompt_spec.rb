require "rails_helper"

RSpec.describe Prompts::GeneratePrompt do
  include ActiveJob::TestHelper

  let(:video) { create(:video, :with_idea) }

  it "creates a generating version, advances the video, and enqueues the job" do
    expect { described_class.call(video, actor: video.project.user) }
      .to have_enqueued_job(GenerateVideoPromptJob).with(kind_of(Integer), kind_of(String))

    video.reload
    prompt = video.current_prompt
    expect(prompt).to be_generating
    expect(prompt.version).to eq(1)
    expect(prompt.generation_id).to be_present
    expect(prompt.source_idea).to eq(video.idea_source)
    expect(video).to be_generating_prompt
  end

  it "increments the version and supersedes the prior draft on regeneration" do
    first = create(:prompt, video: video, version: 1, status: :draft)
    video.update!(status: :prompt_ready)

    expect { described_class.call(video) }
      .to have_enqueued_job(RegenerateVideoPromptJob)

    expect(first.reload).to be_superseded
    latest = video.reload.current_prompt
    expect(latest.version).to eq(2)
    expect(latest).to be_generating
  end

  it "keeps an approved version active while a regeneration is in flight" do
    approved = create(:prompt, :approved, video: video, version: 1)
    video.update!(status: :prompt_ready, active_prompt_id: approved.id)

    described_class.call(video)

    expect(approved.reload).to be_approved
    expect(video.reload.active_prompt_id).to eq(approved.id)
  end

  it "refuses to generate without an idea" do
    empty = create(:video, idea_text: nil, transcript: nil, status: :idea_ready)

    expect { described_class.call(empty) }
      .to raise_error(Prompts::InvalidState, /Add an idea/)
  end

  it "refuses when generation is already in progress" do
    video.update!(status: :generating_prompt)

    expect { described_class.call(video) }
      .to raise_error(Prompts::InvalidState, /already in progress/)
  end
end
