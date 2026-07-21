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
      created = false
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
        created = true
        @character.transition_to!(:awaiting_approval, actor: @actor, reason: "image generated")
      end

      record_usage(image) if created
      image
    end

    private

    # Ledger the billable image generation (Phase 12), keyed by the image so a
    # retried delivery never double-counts.
    def record_usage(image)
      project = @character.project
      Usage::Record.call(
        source: image,
        provider: @character.provider,
        service_type: "character_image",
        model: @character.provider_model,
        user: project&.user,
        project: project,
        provider_request_id: @character.provider_job_id,
        generated_images: 1,
        provider_reported_cost: @character.estimated_cost
      )
    end
  end
end
