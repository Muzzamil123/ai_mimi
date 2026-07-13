# Namespace for authentication service objects and their error hierarchy.
module Auth
  # Base for all auth errors. Controllers rescue AuthenticationError -> 401.
  class AuthenticationError < StandardError; end

  # Wrong email/password.
  class InvalidCredentials < AuthenticationError; end

  # Account is suspended or deleted.
  class AccountInactive < AuthenticationError; end

  # Refresh / reset / verification token is missing, invalid, or expired.
  class InvalidTokenError < AuthenticationError; end
end
