require "digest"

module VideoAssets
  # Step 1: fetch the finished output from the provider and stage it. Computes the
  # checksum and performs duplicate detection — if an identical file was already
  # stored for another output of the same video, this asset is deduped (points at
  # the original, reuses its stored file/thumbnail, and is marked ready) instead
  # of storing the bytes twice. Otherwise the bytes are staged for validation.
  # Idempotent: a no-op once the asset is already stored.
  class Download < ApplicationService
    def initialize(asset, provider: nil, storage: nil)
      @asset = asset
      @generation = asset.video_generation
      @provider = provider || VideoGenerationProviders.build
      @storage = storage || Storage.adapter
    end

    def call
      return @asset if @asset.stored_at.present?

      result = @provider.fetch_asset(job_id: @generation.provider_job_id)
      data = result[:data].to_s
      raise Storage::Error, "Provider returned an empty asset" if data.empty?

      checksum = Digest::SHA256.hexdigest(data)
      original = duplicate_original(checksum)

      if original
        dedupe_from(original, checksum, data.bytesize)
      else
        stage(data, result[:mime_type], checksum)
      end

      @asset
    end

    private

    def stage(data, mime_type, checksum)
      key = staging_key
      @storage.store(key: key, data: data, content_type: mime_type)
      @asset.update!(
        storage_key: key,
        filename: filename,
        mime_type: mime_type,
        file_size: data.bytesize,
        checksum: checksum,
        validation_status: :pending,
        stored_at: nil
      )
    end

    def dedupe_from(original, checksum, byte_size)
      @asset.update!(
        duplicate_of: original,
        storage_key: original.storage_key,
        thumbnail_storage_key: original.thumbnail_storage_key,
        filename: filename,
        mime_type: original.mime_type,
        width: original.width,
        height: original.height,
        duration_seconds: original.duration_seconds,
        file_size: byte_size,
        checksum: checksum,
        validation_status: :valid,
        stored_at: Time.current
      )
    end

    # A ready asset for a *different* output of the same video with identical
    # bytes — the source of a dedupe.
    def duplicate_original(checksum)
      VideoAsset
        .joins(:video_generation)
        .where(video_generations: { video_id: @generation.video_id })
        .where(checksum: checksum)
        .where.not(id: @asset.id)
        .where.not(stored_at: nil)
        .order(:created_at)
        .first
    end

    def staging_key
      "tmp/video-assets/#{@generation.id}.mp4"
    end

    def filename
      "#{@generation.video_id}-#{@generation.aspect_ratio.tr(':', 'x')}-v#{@generation.variation_number}.mp4"
    end
  end
end
