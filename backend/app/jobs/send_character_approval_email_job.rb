# Final step of the character pipeline: mint a secure single-use approval link
# and email the project owner that their character is ready for approval. The
# recipient is always the authenticated account owner's current email (never
# hardcoded).
#
# Idempotent: guarded so it only fires while the character is still awaiting
# approval for this exact generation, and CreateApprovalRequest cancels any prior
# pending link (cancel-and-replace) so a retry never leaves two live tokens.
class SendCharacterApprovalEmailJob < ApplicationJob
  queue_as :mailers

  def perform(character_id, generation_id)
    character = Character.find_by(id: character_id)
    return if character.nil?
    return unless character.awaiting_approval? && character.generation_id == generation_id

    result = Approvals::CreateApprovalRequest.call(character)
    UserMailer.character_approval(character, result.approval_request, result.raw_token).deliver_now
    Notifications::RecordDelivery.call(
      user: character.project.user, email_type: "character_ready",
      project: character.project, dedupe_key: "character_ready:#{character.id}:#{generation_id}",
      subject: %(Your character for "#{character.project.name}" is ready for approval)
    )
  end
end
