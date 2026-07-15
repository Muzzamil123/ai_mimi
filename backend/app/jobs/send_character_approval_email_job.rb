# Step 4 of the character pipeline: email the project owner that their character
# is ready for approval. The recipient is always the authenticated account
# owner's email (never hardcoded). Idempotent — only sends while the character is
# still awaiting approval for this generation, so retries/duplicates don't spam.
class SendCharacterApprovalEmailJob < ApplicationJob
  queue_as :mailers

  def perform(character_id, generation_id)
    character = Character.find_by(id: character_id)
    return if character.nil?
    return unless character.awaiting_approval? && character.generation_id == generation_id

    UserMailer.character_approval(character).deliver_now
  end
end
