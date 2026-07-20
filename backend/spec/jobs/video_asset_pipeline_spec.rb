require "rails_helper"

RSpec.describe "Video asset pipeline jobs" do
  include ActiveJob::TestHelper

  def completed_generation
    video = ready_to_generate_video
    video.update!(status: :generating)
    create(:video_generation, :completed,
           video: video, project: video.project,
           character: video.project.active_character, prompt: video.active_prompt,
           aspect_ratio: "3:4", variation_number: 1)
  end

  it "runs download → validate → thumbnail → store, ending ready" do
    generation = completed_generation

    perform_enqueued_jobs do
      DownloadGeneratedVideoJob.perform_later(generation.id)
    end

    asset = generation.reload.video_asset
    expect(asset).to be_ready
    expect(asset).to be_validation_valid
    expect(asset.thumbnail_storage_key).to be_present
    expect(asset.stored_at).to be_present
    expect(Storage.adapter.exist?(asset.storage_key)).to be(true)
    expect(Storage.adapter.exist?(asset.thumbnail_storage_key)).to be(true)
  end

  it "marks the asset failed on a permanent provider error" do
    generation = completed_generation
    allow(VideoGenerationProviders).to receive(:build).and_return(
      instance_double(VideoGenerationProviders::Fake).tap do |p|
        allow(p).to receive(:fetch_asset)
          .and_raise(VideoGenerationProviders::Error.new("gone", retryable: false))
      end
    )

    DownloadGeneratedVideoJob.perform_now(generation.id)

    expect(generation.reload.video_asset).to be_validation_failed
  end

  it "retries a transient provider error, then fails after exhaustion" do
    generation = completed_generation
    allow(VideoGenerationProviders).to receive(:build).and_return(
      instance_double(VideoGenerationProviders::Fake).tap do |p|
        allow(p).to receive(:fetch_asset)
          .and_raise(VideoGenerationProviders::TimeoutError.new)
      end
    )

    perform_enqueued_jobs { DownloadGeneratedVideoJob.perform_later(generation.id) }

    expect(generation.reload.video_asset).to be_validation_failed
  end

  it "stops at invalid without generating a thumbnail" do
    generation = completed_generation
    # Provider returns an unplayable file.
    allow(VideoGenerationProviders).to receive(:build).and_return(
      instance_double(VideoGenerationProviders::Fake).tap do |p|
        allow(p).to receive(:fetch_asset).and_return({ data: "garbage".b, mime_type: "video/mp4" })
      end
    )

    perform_enqueued_jobs { DownloadGeneratedVideoJob.perform_later(generation.id) }

    asset = generation.reload.video_asset
    expect(asset).to be_validation_invalid
    expect(asset.thumbnail_storage_key).to be_nil
  end

  it "is triggered when a generation completes (Phase 8 → 9 integration)" do
    video = ready_to_generate_video
    video.update!(status: :generating)
    record = create(:video_generation, :processing,
                    video: video, project: video.project,
                    character: video.project.active_character, prompt: video.active_prompt,
                    provider_job_id: "fake-job-3x4-1-abc")

    expect {
      VideoGenerations::ApplyStatus.call(
        record, VideoGenerationProviders::StatusResult.new(state: :completed, progress: 100)
      )
    }.to have_enqueued_job(DownloadGeneratedVideoJob).with(record.id)
  end
end
