class CharacterBlueprint < Blueprinter::Base
  identifier :id

  fields :project_id, :name, :description, :style_preferences,
         :status, :provider, :provider_model, :generation_prompt,
         :failure_reason, :rejection_feedback

  # `character_attributes` is exposed under the documented `attributes` name.
  field :attributes do |character|
    character.character_attributes
  end

  field :locked do |character|
    character.locked?
  end

  field :estimated_cost do |character|
    character.estimated_cost&.to_f
  end

  # Authenticated download path for the latest generated image (nil until one
  # exists). Clients fetch it with their bearer token.
  field :image_url do |character|
    character.latest_image && "/api/v1/projects/#{character.project_id}/character/image"
  end

  association :latest_image, blueprint: CharacterImageBlueprint do |character|
    character.latest_image
  end

  field :approved_at do |character|
    character.approved_at&.iso8601
  end

  field :rejected_at do |character|
    character.rejected_at&.iso8601
  end

  field :locked_at do |character|
    character.locked_at&.iso8601
  end

  field :created_at do |character|
    character.created_at.iso8601
  end

  field :updated_at do |character|
    character.updated_at.iso8601
  end
end
