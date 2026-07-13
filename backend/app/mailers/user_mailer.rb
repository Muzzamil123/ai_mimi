require "uri"

class UserMailer < ApplicationMailer
  # Character-approval, completion, and other workflow emails arrive in later
  # phases. Phase 2 covers account emails only.

  def email_verification(user, token)
    @user = user
    @verify_url = frontend_url("/verify-email", token: token)
    mail(to: @user.email, subject: "Verify your email address")
  end

  def password_reset(user, token)
    @user = user
    @reset_url = frontend_url("/reset-password", token: token)
    mail(to: @user.email, subject: "Reset your password")
  end

  private

  # Builds a link into the React app. Base URL is env-driven so links are correct
  # per environment.
  def frontend_url(path, **query)
    uri = URI.join(ENV.fetch("FRONTEND_URL", "http://localhost:5173"), path)
    uri.query = query.to_query if query.any?
    uri.to_s
  end
end
