# Pipeline entry (Phase 9): create the asset record for a completed generation,
# download the output from the provider, and hand off to validation (unless the
# file was deduped, in which case it is already ready). Keyed by generation_id,
# so it overrides the base retry-exhaustion handler to resolve the asset via the
# generation.
class DownloadGeneratedVideoJob < VideoAssets::ProcessingJob
  retry_on VideoAssets::TransientError, wait: :polynomially_longer, attempts: 5 do |job, error|
    asset = VideoGeneration.find_by(id: job.arguments.first)&.video_asset
    VideoAssets::ProcessingJob.fail_asset(asset, detail: error.message)
  end

  def perform(generation_id)
    generation = VideoGeneration.find_by(id: generation_id)
    return if generation.nil? || !generation.completed?

    asset = generation.video_asset || generation.create_video_asset!

    process_step(asset.id) do |current|
      VideoAssets::Download.call(current)
      current.reload
      ValidateGeneratedVideoJob.perform_later(current.id) unless current.ready?
    end
  end
end
