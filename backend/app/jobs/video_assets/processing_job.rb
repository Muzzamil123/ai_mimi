module VideoAssets
  # Base class for the asset processing pipeline (download → validate → thumbnail
  # → store). Provides the shared idempotency guard and error handling: a
  # retryable provider error is retried with backoff; a storage or unexpected
  # error marks the asset's processing failed (surfaced in the UI) — never
  # stranded. Note: a video that simply fails *validation* (wrong duration/aspect)
  # is an `invalid` outcome set by the service, not an error handled here.
  class ProcessingJob < ApplicationJob
    queue_as :ai_generation

    retry_on VideoAssets::TransientError, wait: :polynomially_longer, attempts: 5 do |job, error|
      ProcessingJob.fail_asset(VideoAsset.find_by(id: job.arguments.first), detail: error.message)
    end

    # Marks an asset's processing failed and reclaims its staged bytes. Class
    # method so retry-exhaustion handlers (here and the download job's override)
    # can reuse it.
    def self.fail_asset(asset, detail:)
      return if asset.nil?

      asset.update!(validation_status: :failed)
      VideoAssets.delete_staging(asset)
      Rails.logger.warn(message: "video_asset_failed", asset_id: asset.id, detail: detail.to_s.truncate(500))
    end

    protected

    def process_step(asset_id)
      asset = VideoAsset.find_by(id: asset_id)
      return if asset.nil?

      yield asset
    rescue VideoGenerationProviders::Error => e
      raise VideoAssets::TransientError, e.message if e.retryable

      mark_failed(asset, e.message)
    rescue Storage::Error => e
      mark_failed(asset, e.message)
    rescue StandardError => e
      Rails.logger.error(
        message: "video_asset_processing_error",
        asset_id: asset&.id, error: e.class.name, detail: e.message
      )
      mark_failed(asset, e.message)
    end

    private

    def mark_failed(asset, message)
      self.class.fail_asset(asset, detail: message)
    end
  end
end
