class CharacterImageBlueprint < Blueprinter::Base
  identifier :id

  # `storage_key` is intentionally omitted — it is an internal storage detail.
  # Bytes are served through the authenticated image download endpoint.
  fields :character_id, :mime_type, :width, :height, :file_size,
         :checksum, :provider_asset_id

  field :created_at do |image|
    image.created_at.iso8601
  end
end
