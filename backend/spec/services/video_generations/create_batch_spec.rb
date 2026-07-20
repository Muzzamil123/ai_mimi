require "rails_helper"

RSpec.describe VideoGenerations::CreateBatch do
  include ActiveJob::TestHelper

  def queued_video
    video = ready_to_generate_video
    video.update!(status: :queued)
    video
  end

  it "creates exactly four generation records (2 aspect ratios × 2 variations)" do
    video = queued_video

    described_class.call(video)

    generations = video.video_generations
    expect(generations.count).to eq(4)
    expect(generations.pluck(:aspect_ratio).tally).to eq("3:4" => 2, "9:16" => 2)
    expect(generations.pluck(:variation_number).uniq).to contain_exactly(1, 2)
  end

  it "attaches the approved character and prompt to every record" do
    video = queued_video

    described_class.call(video)

    expect(video.video_generations.pluck(:character_id).uniq).to eq([ video.project.active_character_id ])
    expect(video.video_generations.pluck(:prompt_id).uniq).to eq([ video.active_prompt_id ])
    expect(video.video_generations.pluck(:duration_seconds).uniq).to eq([ 15 ])
  end

  it "moves the video to generating and enqueues a submit job per record" do
    video = queued_video

    expect { described_class.call(video) }
      .to have_enqueued_job(SubmitVideoGenerationJob).exactly(4).times

    expect(video.reload).to be_generating
  end

  it "is idempotent — a re-run creates no duplicates" do
    video = queued_video
    described_class.call(video)

    expect { described_class.call(video.reload) }.not_to change(VideoGeneration, :count)
  end
end
