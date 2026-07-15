# Step 1 of the character pipeline: build and persist the image-generation
# prompt, then hand off to image generation.
class GenerateCharacterPromptJob < Characters::GenerationJob
  def perform(character_id, generation_id)
    with_active_generation(character_id, generation_id) do |character|
      Characters::GeneratePrompt.call(character)
      GenerateCharacterImageJob.perform_later(character.id, generation_id)
    end
  end
end
