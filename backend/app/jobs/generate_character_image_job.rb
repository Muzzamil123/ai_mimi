# Step 2 of the character pipeline: call the image provider, store the asset,
# then hand off to the download/finalize step.
class GenerateCharacterImageJob < Characters::GenerationJob
  def perform(character_id, generation_id)
    with_active_generation(character_id, generation_id) do |character|
      staged = Characters::GenerateImage.call(character, generation_id)
      DownloadCharacterImageJob.perform_later(
        character.id,
        generation_id,
        staged.storage_key,
        staged.mime_type,
        staged.provider_asset_id
      )
    end
  end
end
