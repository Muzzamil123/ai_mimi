module Characters
  # Calls the image provider (Gemini in production, Fake otherwise), stores the
  # returned bytes via the Storage abstraction, and records provider metadata on
  # the character. Returns a StagedImage describing where the asset landed so the
  # download/finalize step can build the CharacterImage record.
  class GenerateImage < ApplicationService
    StagedImage = Struct.new(:storage_key, :mime_type, :provider_asset_id, keyword_init: true)

    def initialize(character, generation_id, provider: nil, storage: nil)
      @character = character
      @generation_id = generation_id
      @provider = provider || CharacterImageProviders.build
      @storage = storage || Storage.adapter
    end

    def call
      result = @provider.generate(
        prompt: @character.generation_prompt.to_s,
        options: { style_preferences: @character.style_preferences }
      )

      key = storage_key(result.mime_type)
      @storage.store(key: key, data: result.image_data, content_type: result.mime_type)

      @character.update!(
        provider: result.provider,
        provider_model: result.model,
        provider_job_id: result.provider_request_id,
        estimated_cost: result.estimated_cost
      )

      StagedImage.new(
        storage_key: key,
        mime_type: result.mime_type,
        provider_asset_id: result.provider_asset_id
      )
    end

    private

    # Namespaced by character and generation so regenerations never collide and
    # prior attempts remain retrievable.
    def storage_key(mime_type)
      ext = Characters.extension_for(mime_type)
      "characters/#{@character.id}/#{@generation_id}/source.#{ext}"
    end
  end
end
