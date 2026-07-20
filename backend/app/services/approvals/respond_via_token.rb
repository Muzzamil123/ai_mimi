module Approvals
  # Shared base for the approve/reject-via-token actions. Enforces that the
  # single-use link is still actionable (pending and unexpired) and that the
  # character is still awaiting approval, then delegates the state change to the
  # existing Characters::* services so the character/project state machine stays
  # the single source of truth. The owning account is recorded as the actor.
  class RespondViaToken < ApplicationService
    def initialize(approval_request)
      @request = approval_request
      @character = approval_request.character
    end

    def call
      guard_actionable_link!
      guard_character_awaiting!

      ApprovalRequest.transaction do
        # Mark this request first so the character transition's pending-link sweep
        # (Character#void_pending_approval_requests!) leaves it alone.
        @request.update!(response_attributes)
        apply!
      end

      Rails.logger.info(message: log_event, approval_request_id: @request.id, character_id: @character.id)
      deliver_confirmation
      @request
    end

    private

    # Subclasses implement the character-side effect, the persisted response
    # attributes, the log event name, and the confirmation email.
    def apply!            = raise NotImplementedError
    def response_attributes = raise NotImplementedError
    def log_event         = raise NotImplementedError
    def deliver_confirmation = raise NotImplementedError

    def actor
      @request.user
    end

    def guard_actionable_link!
      return if @request.actionable?

      # Expired (or pending-but-past-expiry) → expired; any other non-actionable
      # state (approved/rejected/cancelled) → already used.
      if @request.expired? || (@request.pending? && @request.past_expiry?)
        @request.update!(status: :expired) if @request.pending?
        raise Approvals::LinkExpired, "This approval link has expired"
      end

      raise Approvals::AlreadyProcessed, "This approval link has already been used"
    end

    # Guards against the link being valid while the character moved on out of band
    # (e.g. an admin reset, or approval through the authenticated portal).
    def guard_character_awaiting!
      return if @character.awaiting_approval?

      raise Approvals::AlreadyProcessed, "This character is no longer awaiting approval"
    end
  end
end
