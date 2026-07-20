module VideoAssets
  # Step 4: promote the validated file from its staging key to its permanent
  # location and mark the asset stored (ready to serve). Deduped assets are
  # already stored (they reuse the original's file), so this is a no-op for them.
  class Store < ApplicationService
    def initialize(asset, storage: nil)
      @asset = asset
      @storage = storage || Storage.adapter
    end

    def call
      return @asset if @asset.stored_at.present?

      permanent = permanent_key
      if @asset.storage_key != permanent
        data = @storage.read(@asset.storage_key)
        raise Storage::Error, "Validated asset missing from storage: #{@asset.storage_key}" if data.nil?

        @storage.store(key: permanent, data: data, content_type: @asset.mime_type)
        @storage.delete(@asset.storage_key)
        @asset.update!(storage_key: permanent)
      end

      @asset.update!(stored_at: Time.current)
      @asset
    end

    private

    def permanent_key
      "videos/#{@asset.video_generation.video_id}/assets/#{@asset.video_generation_id}.mp4"
    end
  end
end
