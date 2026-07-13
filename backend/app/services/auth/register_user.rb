module Auth
  # Creates a new (unverified) user account and sends the verification email.
  # Raises ActiveRecord::RecordInvalid on validation failure.
  class RegisterUser < ApplicationService
    def initialize(params)
      @params = params
    end

    def call
      user = User.create!(
        name: @params[:name],
        email: @params[:email],
        password: @params[:password]
      )

      UserMailer.email_verification(user, user.generate_token_for(:email_verification)).deliver_later
      user
    end
  end
end
