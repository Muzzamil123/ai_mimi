module VideoAssets
  # Step 3: generate a poster thumbnail from the validated video and store it.
  class GenerateThumbnail < ApplicationService
    def initialize(asset, storage: nil, generator: nil)
      @asset = asset
      @storage = storage || Storage.adapter
      @generator = generator || Media::Thumbnail.build
    end

    def call
      data = @storage.read(@asset.storage_key)
      raise Storage::Error, "Asset missing from storage: #{@asset.storage_key}" if data.nil?

      thumbnail = @generator.generate(data, mime_type: @asset.mime_type)
      key = thumbnail_key
      @storage.store(key: key, data: thumbnail, content_type: Media::Thumbnail::MIME_TYPE)

      @asset.update!(thumbnail_storage_key: key)
      @asset
    end

    private

    def thumbnail_key
      "videos/#{@asset.video_generation.video_id}/thumbnails/#{@asset.video_generation_id}.jpg"
    end
  end
end
