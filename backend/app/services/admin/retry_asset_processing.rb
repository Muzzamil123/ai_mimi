module Admin
  # Re-runs the download/validation/thumbnail/storage pipeline for a completed
  # generation whose asset failed or was rejected as invalid. Resets the asset
  # to a reprocessable state (clears the stored file marker) so the otherwise
  # idempotent Download step actually runs again, then re-enqueues the pipeline.
  class RetryAssetProcessing < ApplicationService
    def initialize(video_generation, actor: nil)
      @generation = video_generation
      @actor = actor
    end

    def call
      unless @generation.completed?
        raise Admin::InvalidOperation, "Asset processing can only be retried for a completed output"
      end

      asset = @generation.video_asset
      asset&.update!(validation_status: :pending, stored_at: nil)

      DownloadGeneratedVideoJob.perform_later(@generation.id)
      @generation
    end
  end
end
