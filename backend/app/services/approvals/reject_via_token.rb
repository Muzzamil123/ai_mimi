module Approvals
  # Rejects the character behind a valid, unexpired, single-use approval link,
  # recording the owner's feedback (on both the request and the character, via
  # Characters::RejectCharacter) so the next generation can incorporate it, then
  # emails a rejection confirmation. The project moves to `character_rejected`,
  # from which the same project can regenerate.
  class RejectViaToken < RespondViaToken
    def initialize(approval_request, feedback: nil)
      super(approval_request)
      @feedback = feedback.presence
    end

    private

    def apply!
      Characters::RejectCharacter.call(@character, feedback: @feedback, actor: actor)
    end

    def response_attributes
      { status: :rejected, feedback: @feedback, responded_at: Time.current }
    end

    def log_event
      "approval_request_rejected"
    end

    def deliver_confirmation
      UserMailer.character_rejected(@character.reload).deliver_later
      Notifications::RecordDelivery.call(
        user: @character.project.user, email_type: "character_rejected",
        project: @character.project, dedupe_key: "character_rejected:#{@character.id}:#{@character.generation_id}"
      )
    end
  end
end
