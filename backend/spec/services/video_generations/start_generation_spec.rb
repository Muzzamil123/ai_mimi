require "rails_helper"

RSpec.describe VideoGenerations::StartGeneration do
  include ActiveJob::TestHelper

  it "moves the video to queued and enqueues the batch job" do
    video = ready_to_generate_video

    expect { described_class.call(video, actor: video.project.user) }
      .to have_enqueued_job(CreateVideoGenerationBatchJob).with(video.id)

    expect(video.reload).to be_queued
  end

  it "requires an approved prompt" do
    video = ready_to_generate_video
    video.update!(active_prompt_id: nil)

    expect { described_class.call(video) }
      .to raise_error(VideoGenerations::InvalidState, /Approve a prompt/)
  end

  it "requires an approved character" do
    video = ready_to_generate_video
    video.project.update!(active_character_id: nil)

    expect { described_class.call(video) }
      .to raise_error(VideoGenerations::InvalidState, /character must be approved/)
  end

  it "requires the approved character to have an image" do
    video = ready_to_generate_video
    video.project.active_character.images.destroy_all

    expect { described_class.call(video) }
      .to raise_error(VideoGenerations::InvalidState, /no image/)
  end

  it "prevents a duplicate request while generation is in progress" do
    video = ready_to_generate_video
    described_class.call(video)

    expect { described_class.call(video.reload) }
      .to raise_error(VideoGenerations::InvalidState, /already in progress/)
  end
end
