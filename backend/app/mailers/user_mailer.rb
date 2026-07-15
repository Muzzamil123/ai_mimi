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

  # Notifies the project owner that their generated character is awaiting
  # approval. Sent to the authenticated account owner's email (business rule);
  # Phase 5 adds a tokenized one-click approval link.
  def character_approval(character)
    @character = character
    @project = character.project
    @user = @project.user
    @review_url = frontend_url("/projects/#{@project.id}/character")
    mail(to: @user.email, subject: %(Your character for "#{@project.name}" is ready for approval))
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
