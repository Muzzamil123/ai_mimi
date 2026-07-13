module Auth
  # Consumes an email-verification token and marks the account verified.
  # Raises InvalidTokenError.
  class VerifyEmail < ApplicationService
    def initialize(token)
      @token = token
    end

    def call
      user = User.find_by_token_for(:email_verification, @token)
      raise InvalidTokenError, "Invalid or expired verification token" unless user

      user.mark_email_verified!
      user
    end
  end
end
