module VideoAssets
  # Step 2: validate the staged file. Checks file type, that it is a playable
  # video, its duration (must match the 15-second output within tolerance), and
  # its aspect ratio (must match the requested 3:4 / 9:16). Records the probed
  # dimensions/duration and sets validation_status to valid or invalid. A failed
  # *validation* (wrong duration/aspect/not playable) is a normal outcome, not an
  # error — the pipeline stops without retrying.
  class Validate < ApplicationService
    def initialize(asset, storage: nil, inspector: nil)
      @asset = asset
      @generation = asset.video_generation
      @storage = storage || Storage.adapter
      @inspector = inspector || Media::VideoInfo.build
    end

    def call
      unless VideoAssets::ALLOWED_MIME_TYPES.include?(@asset.mime_type)
        return mark_invalid("Unsupported file type: #{@asset.mime_type}")
      end

      data = @storage.read(@asset.storage_key)
      raise Storage::Error, "Staged asset missing from storage: #{@asset.storage_key}" if data.nil?

      info = @inspector.probe(data, mime_type: @asset.mime_type)
      return mark_invalid("File is not a playable video") unless info.playable?

      @asset.update!(width: info.width, height: info.height, duration_seconds: info.duration_seconds)

      unless duration_ok?(info.duration_seconds)
        return mark_invalid("Unexpected duration: #{info.duration_seconds}s (expected #{@generation.duration_seconds}s)")
      end
      unless aspect_ok?(info.width, info.height)
        return mark_invalid("Unexpected aspect ratio for #{@generation.aspect_ratio}")
      end

      @asset.update!(validation_status: :valid)
      @asset
    end

    private

    def duration_ok?(actual)
      return false if actual.nil?

      (actual - @generation.duration_seconds).abs <= VideoAssets::DURATION_TOLERANCE_SECONDS
    end

    def aspect_ok?(width, height)
      expected = VideoAssets.expected_ratio(@generation.aspect_ratio)
      return false if expected.nil? || width.to_i <= 0 || height.to_i <= 0

      (width.to_f / height.to_f - expected).abs <= VideoAssets::ASPECT_RATIO_TOLERANCE
    end

    def mark_invalid(reason)
      @asset.update!(validation_status: :invalid)
      # An invalid asset is never served, so reclaim its staged bytes.
      VideoAssets.delete_staging(@asset, storage: @storage)
      Rails.logger.info(message: "video_asset_invalid", asset_id: @asset.id, reason: reason)
      @asset
    end
  end
end
