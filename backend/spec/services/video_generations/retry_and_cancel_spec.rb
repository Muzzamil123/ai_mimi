require "rails_helper"

RSpec.describe "VideoGenerations retry + cancel" do
  include ActiveJob::TestHelper

  def video_with_variants(statuses, video_status:)
    video = ready_to_generate_video
    video.update!(status: video_status)
    records = statuses.each_with_index.map do |status, index|
      create(:video_generation, status,
             video: video, project: video.project,
             character: video.project.active_character, prompt: video.active_prompt,
             aspect_ratio: index.even? ? "3:4" : "9:16", variation_number: (index % 2) + 1)
    end
    [ video, records ]
  end

  describe VideoGenerations::RetryGeneration do
    it "resets a failed variant and re-enqueues submission" do
      video, records = video_with_variants(%i[completed completed completed failed], video_status: :partially_completed)
      failed = records.last

      expect { described_class.call(failed, actor: video.project.user) }
        .to have_enqueued_job(RetryVideoGenerationJob).with(failed.id)

      expect(failed.reload).to be_pending
      expect(video.reload).to be_generating
    end

    it "can retry when the whole batch failed (video failed -> generating)" do
      video, records = video_with_variants(%i[failed failed failed failed], video_status: :failed)

      described_class.call(records.first)

      expect(records.first.reload).to be_pending
      expect(video.reload).to be_generating
    end

    it "refuses to retry a non-failed variant" do
      video, records = video_with_variants(%i[completed completed completed completed], video_status: :completed)

      expect { described_class.call(records.first) }
        .to raise_error(VideoGenerations::InvalidState, /Only a failed/)
    end
  end

  describe VideoGenerations::CancelGeneration do
    it "cancels active variants and the video, preserving finished ones" do
      video, records = video_with_variants(%i[completed processing pending failed], video_status: :generating)

      described_class.call(video, actor: video.project.user)

      expect(video.reload).to be_cancelled
      expect(records[0].reload).to be_completed
      expect(records[1].reload).to be_cancelled
      expect(records[2].reload).to be_cancelled
      expect(records[3].reload).to be_failed
    end

    it "refuses to cancel when there is no active generation" do
      video, = video_with_variants(%i[completed completed completed completed], video_status: :completed)

      expect { described_class.call(video) }
        .to raise_error(VideoGenerations::InvalidState, /no active generation/)
    end
  end
end
