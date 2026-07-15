require "digest"

module Characters
  # Finalizes a generated asset: reads the stored bytes back, verifies them,
  # derives dimensions/checksum/size, records the CharacterImage, and moves the
  # character into `awaiting_approval`. Kept separate from generation so a
  # provider that returns a remote URL can be downloaded here without changing
  # the rest of the pipeline.
  class StoreGeneratedImage < ApplicationService
    def initialize(character, storage_key:, mime_type:, provider_asset_id: nil, storage: nil, actor: nil)
      @character = character
      @storage_key = storage_key
      @mime_type = mime_type
      @provider_asset_id = provider_asset_id
      @storage = storage || Storage.adapter
      @actor = actor
    end

    def call
      data = @storage.read(@storage_key)
      raise Storage::Error, "Generated asset missing from storage: #{@storage_key}" if data.nil?

      dimensions = Media::ImageInfo.dimensions(data)

      image = nil
      @character.with_lock do
        # Idempotent under concurrent delivery: if a sibling job already
        # finalized this generation, don't create a duplicate image.
        break image = @character.latest_image unless @character.generating?

        image = @character.images.create!(
          storage_key: @storage_key,
          original_filename: "character-#{@character.id}.#{Characters.extension_for(@mime_type)}",
          mime_type: @mime_type,
          width: dimensions.width,
          height: dimensions.height,
          file_size: data.bytesize,
          checksum: Digest::SHA256.hexdigest(data),
          provider_asset_id: @provider_asset_id
        )
        @character.transition_to!(:awaiting_approval, actor: @actor, reason: "image generated")
      end

      image
    end
  end
end
