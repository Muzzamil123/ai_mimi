require "rails_helper"

RSpec.describe "Video generation jobs" do
  include ActiveJob::TestHelper

  def generating_video
    video = ready_to_generate_video
    video.update!(status: :generating)
    video
  end

  def record_for(video, status: :pending)
    create(:video_generation, status,
           video: video, project: video.project,
           character: video.project.active_character, prompt: video.active_prompt)
  end

  describe CreateVideoGenerationBatchJob do
    it "creates the four records and enqueues submissions" do
      video = ready_to_generate_video
      video.update!(status: :queued)

      perform_enqueued_jobs(only: CreateVideoGenerationBatchJob) do
        described_class.perform_later(video.id)
      end

      expect(video.video_generations.count).to eq(4)
    end
  end

  describe SubmitVideoGenerationJob do
    it "submits and drives the variant to completion via the fake provider" do
      video = generating_video
      record = record_for(video)

      perform_enqueued_jobs { described_class.perform_later(record.id) }

      expect(record.reload).to be_completed
    end

    it "no-ops for a non-pending record" do
      video = generating_video
      record = record_for(video, status: :completed)

      described_class.perform_now(record.id)

      expect(record.reload).to be_completed
    end

    it "retries on a transient provider error, then fails the variant" do
      video = generating_video
      record = record_for(video)
      allow(VideoGenerationProviders).to receive(:build).and_return(
        instance_double(VideoGenerationProviders::Fake).tap do |p|
          allow(p).to receive(:create_generation)
            .and_raise(VideoGenerationProviders::RateLimited.new("slow down"))
        end
      )

      perform_enqueued_jobs { described_class.perform_later(record.id) }

      expect(record.reload).to be_failed
      expect(record.error_message).to match(/after retries/)
    end

    it "fails immediately (no retry) on a permanent provider error" do
      video = generating_video
      record = record_for(video)
      allow(VideoGenerationProviders).to receive(:build).and_return(
        instance_double(VideoGenerationProviders::Fake).tap do |p|
          allow(p).to receive(:create_generation)
            .and_raise(VideoGenerationProviders::Error.new("bad prompt", retryable: false, code: "bad_request"))
        end
      )

      described_class.perform_now(record.id)

      expect(record.reload).to be_failed
      expect(record.error_code).to eq("bad_request")
    end
  end

  describe PollVideoGenerationStatusJob do
    it "fails the variant when the polling deadline is exceeded" do
      video = generating_video
      record = record_for(video)
      record.update!(provider_job_id: "job-1")
      record.transition_to!(:processing)
      allow(VideoGenerationProviders).to receive(:build).and_return(
        instance_double(VideoGenerationProviders::Fake).tap do |p|
          allow(p).to receive(:fetch_status)
            .and_return(VideoGenerationProviders::StatusResult.new(state: :processing, progress: 10))
        end
      )

      described_class.perform_now(record.id, 9999)

      expect(record.reload).to be_failed
      expect(record.error_code).to eq("timeout")
    end
  end

  describe HandleVideoGenerationWebhookJob do
    it "applies a completed status to the matching variant" do
      video = generating_video
      record = record_for(video)
      record.update!(provider_job_id: "job-77")
      record.transition_to!(:processing)

      described_class.perform_now({ "job_id" => "job-77", "status" => "completed" })

      expect(record.reload).to be_completed
    end

    it "ignores an unknown job id" do
      expect { described_class.perform_now({ "job_id" => "nope", "status" => "completed" }) }
        .not_to raise_error
    end
  end
end
