# Namespace for the email character-approval workflow (Phase 5) and its errors.
module Approvals
  # Raised when a presented token is blank, unknown, or tampered with.
  class InvalidToken < StandardError; end

  # Raised when a token is valid but its approval link has passed its expiry.
  class LinkExpired < StandardError; end

  # Raised when the request is no longer pending (already approved/rejected/
  # cancelled), i.e. a duplicate click on a spent single-use link.
  class AlreadyProcessed < StandardError; end
end
