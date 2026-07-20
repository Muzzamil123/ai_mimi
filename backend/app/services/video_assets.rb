# Namespace for asset download/validation/storage/delivery service objects and
# their errors (Phase 9). Turns a completed VideoGeneration output into a stored,
# validated, thumbnailed, securely-downloadable VideoAsset.
module VideoAssets
  # Raised when an asset validation status transition is not permitted.
  class InvalidTransition < StandardError; end

  # Signals a transient failure (provider/storage) that Sidekiq should retry. On
  # exhaustion the asset is marked failed (see VideoAssets::ProcessingJob).
  class TransientError < StandardError; end

  # Video container types accepted for a generated output.
  ALLOWED_MIME_TYPES = %w[video/mp4 video/webm video/quicktime].freeze

  # Tolerances for validating probed metadata against the expected output.
  DURATION_TOLERANCE_SECONDS = 1
  ASPECT_RATIO_TOLERANCE = 0.05

  # Expected width:height ratios per aspect ratio (portrait short-form).
  ASPECT_RATIO_VALUES = {
    "3:4" => 3.0 / 4.0,
    "9:16" => 9.0 / 16.0
  }.freeze

  def self.expected_ratio(aspect_ratio)
    ASPECT_RATIO_VALUES[aspect_ratio.to_s]
  end

  # Prefix of the temporary staging keys used before an asset is permanently
  # stored. Permanent/deduped keys never carry this prefix, so cleanup is safe.
  STAGING_KEY_PREFIX = "tmp/video-assets/".freeze

  # Best-effort deletion of an asset's staged (not yet permanent) bytes. A no-op
  # once the asset has been promoted to its permanent key or is a dedupe.
  def self.delete_staging(asset, storage: Storage.adapter)
    key = asset&.storage_key.to_s
    storage.delete(key) if key.start_with?(STAGING_KEY_PREFIX)
  end
end
