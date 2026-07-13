module Auth
  # Sends a password-reset email if the account exists and is active. Always
  # returns without signalling existence (caller responds 202 regardless) to
  # prevent user enumeration.
  class RequestPasswordReset < ApplicationService
    def initialize(email)
      @email = email
    end

    def call
      user = User.find_by(email: @email.to_s.strip.downcase)
      return unless user&.status_active?

      UserMailer.password_reset(user, user.generate_token_for(:password_reset)).deliver_later
    end
  end
end
