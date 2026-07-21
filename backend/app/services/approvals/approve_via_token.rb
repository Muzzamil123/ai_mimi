module Approvals
  # Approves the character behind a valid, unexpired, single-use approval link.
  # Locks the character and moves the project to `ready` via the existing
  # Characters::ApproveCharacter service, marks the request approved, and emails
  # an approval confirmation to the project owner's current account email.
  class ApproveViaToken < RespondViaToken
    private

    def apply!
      Characters::ApproveCharacter.call(@character, actor: actor)
    end

    def response_attributes
      { status: :approved, responded_at: Time.current }
    end

    def log_event
      "approval_request_approved"
    end

    def deliver_confirmation
      UserMailer.character_approved(@character.reload).deliver_later
      Notifications::RecordDelivery.call(
        user: @character.project.user, email_type: "character_approved",
        project: @character.project, dedupe_key: "character_approved:#{@character.id}"
      )
    end
  end
end
