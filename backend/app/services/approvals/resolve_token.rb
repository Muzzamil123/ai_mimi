module Approvals
  # Resolves a raw approval token to its ApprovalRequest via digest lookup
  # (tampered/unknown tokens simply do not match any digest). Lazily flips a
  # pending-but-past-expiry request to `expired` so reads always reflect the
  # effective state. Unknown tokens are logged as suspicious attempts.
  #
  # Returns the ApprovalRequest in whatever state it resolves to; raises
  # Approvals::InvalidToken when nothing matches.
  class ResolveToken < ApplicationService
    def initialize(raw_token, request_context: {})
      @raw = raw_token
      @request_context = request_context
    end

    def call
      raise Approvals::InvalidToken, "Invalid approval link" if @raw.blank?

      request = ApprovalRequest.find_by(token_digest: ApprovalRequest.digest(@raw))
      if request.nil?
        Rails.logger.warn(
          message: "approval_token_not_found",
          ip_address: @request_context[:ip_address]
        )
        raise Approvals::InvalidToken, "Invalid approval link"
      end

      request.update!(status: :expired) if request.pending? && request.past_expiry?
      request
    end
  end
end
