module Auth
  # Verifies email + password credentials and returns the user.
  # Raises InvalidCredentials or AccountInactive.
  class AuthenticateUser < ApplicationService
    # A throwaway digest used to spend roughly the same time on a bcrypt compare
    # when the account does not exist, so response timing doesn't leak whether an
    # email is registered.
    DUMMY_DIGEST = BCrypt::Password.create("timing-safety-dummy-secret").to_s.freeze

    def initialize(email, password)
      @email = email
      @password = password
    end

    def call
      user = User.find_by(email: @email.to_s.strip.downcase)

      raise InvalidCredentials, "Invalid email or password" unless verify_password(user)
      raise AccountInactive, "This account is #{user.status}" unless user.status_active?

      user.touch_last_login!
      user
    end

    private

    def verify_password(user)
      return user.authenticate(@password) if user

      # No such user: still run a bcrypt comparison to equalize timing.
      BCrypt::Password.new(DUMMY_DIGEST).is_password?(@password)
      false
    end
  end
end
