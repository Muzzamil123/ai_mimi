module Auth
  # Consumes a password-reset token, sets the new password, and revokes all
  # existing sessions. Raises InvalidTokenError or ActiveRecord::RecordInvalid.
  class ResetPassword < ApplicationService
    def initialize(token, password)
      @token = token
      @password = password
    end

    def call
      user = User.find_by_token_for(:password_reset, @token)
      raise InvalidTokenError, "Invalid or expired reset token" unless user

      user.update!(password: @password)
      user.refresh_tokens.active.find_each(&:revoke!)
      user
    end
  end
end
