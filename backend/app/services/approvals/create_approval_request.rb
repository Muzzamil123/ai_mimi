module Approvals
  # Mints a secure, single-use, expiring approval request for a character that is
  # awaiting approval, and returns the raw link token (to be emailed once and
  # never persisted). Any still-pending request for the same character is
  # cancelled so only the newest link is ever valid — this also makes the
  # sending job idempotent under retries/regeneration (cancel-and-replace).
  #
  # The recipient is always resolved from the project owner's CURRENT account
  # email (mandatory business rule — never hardcoded, never a stale value).
  class CreateApprovalRequest < ApplicationService
    Result = Struct.new(:approval_request, :raw_token, keyword_init: true)

    def initialize(character)
      @character = character
      @project = character.project
    end

    def call
      owner = @project.user
      raw, digest = ApprovalRequest.generate_token

      approval_request = nil
      ApprovalRequest.transaction do
        @character.void_pending_approval_requests!
        approval_request = @character.approval_requests.create!(
          project: @project,
          user: owner,
          recipient_email: owner.email,
          token_digest: digest,
          status: :pending,
          expires_at: ttl_hours.hours.from_now
        )
      end

      Result.new(approval_request: approval_request, raw_token: raw)
    end

    private

    def ttl_hours
      Rails.application.config.x.approvals.link_ttl_hours
    end
  end
end
