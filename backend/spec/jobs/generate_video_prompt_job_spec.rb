require "rails_helper"

RSpec.describe GenerateVideoPromptJob do
  include ActiveJob::TestHelper

  let(:video) { create(:video, :with_idea, status: :generating_prompt) }

  def generating_prompt
    create(:prompt, :generating, video: video, content: nil)
  end

  it "generates content with the local provider and advances prompt + video" do
    prompt = generating_prompt

    described_class.perform_now(prompt.id, prompt.generation_id)

    expect(prompt.reload).to be_draft
    expect(prompt.content).to be_present
    expect(video.reload).to be_prompt_ready
  end

  it "no-ops for a superseded generation_id" do
    prompt = generating_prompt

    described_class.perform_now(prompt.id, "stale")

    expect(prompt.reload).to be_generating
    expect(video.reload).to be_generating_prompt
  end

  it "retries on a transient provider error, then fails after exhaustion" do
    prompt = generating_prompt
    allow(TextGenerationProviders).to receive(:build).and_return(
      instance_double(TextGenerationProviders::Local).tap do |p|
        allow(p).to receive(:generate_video_prompt)
          .and_raise(TextGenerationProviders::Error.new("timeout", retryable: true))
      end
    )

    perform_enqueued_jobs { described_class.perform_later(prompt.id, prompt.generation_id) }

    expect(prompt.reload).to be_failed
    expect(video.reload).to be_failed
    expect(prompt.failure_reason).to match(/after retries/)
  end

  it "fails immediately (no retry) on a permanent provider error" do
    prompt = generating_prompt
    allow(TextGenerationProviders).to receive(:build).and_return(
      instance_double(TextGenerationProviders::Local).tap do |p|
        allow(p).to receive(:generate_video_prompt)
          .and_raise(TextGenerationProviders::Error.new("bad request", retryable: false))
      end
    )

    described_class.perform_now(prompt.id, prompt.generation_id)

    expect(prompt.reload).to be_failed
    expect(prompt.failure_reason).to eq("bad request")
  end
end
