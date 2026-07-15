# Step 3 of the character pipeline: finalize the generated asset into a
# CharacterImage record, move the character to `awaiting_approval`, then trigger
# the approval email. Named "download" because for remote-asset providers this
# is where the asset is fetched; for inline providers it verifies the stored bytes.
class DownloadCharacterImageJob < Characters::GenerationJob
  def perform(character_id, generation_id, storage_key, mime_type, provider_asset_id = nil)
    with_active_generation(character_id, generation_id) do |character|
      Characters::StoreGeneratedImage.call(
        character,
        storage_key: storage_key,
        mime_type: mime_type,
        provider_asset_id: provider_asset_id
      )
      SendCharacterApprovalEmailJob.perform_later(character.id, generation_id)
    end
  end
end
