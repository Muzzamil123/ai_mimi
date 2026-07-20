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
  # approval, with a secure single-use link (approve/reject/review all resolve
  # the same token). Sent to the authenticated account owner's current email
  # (mandatory business rule).
  def character_approval(character, approval_request, raw_token)
    @character = character
    @project = character.project
    @user = @project.user
    @approval_request = approval_request
    @expires_at = approval_request.expires_at
    @approve_url = approval_url(raw_token, intent: "approve")
    @reject_url = approval_url(raw_token, intent: "reject")
    @review_url = approval_url(raw_token)
    mail(to: @user.email, subject: %(Your character for "#{@project.name}" is ready for approval))
  end

  # Confirms the character was approved and the project is ready for videos.
  def character_approved(character)
    @character = character
    @project = character.project
    @user = @project.user
    @project_url = frontend_url("/projects/#{@project.id}/character")
    mail(to: @user.email, subject: %(Your character for "#{@project.name}" is approved))
  end

  # Confirms the character was rejected and can be regenerated in the project.
  def character_rejected(character)
    @character = character
    @project = character.project
    @user = @project.user
    @feedback = character.rejection_feedback
    @project_url = frontend_url("/projects/#{@project.id}/character")
    mail(to: @user.email, subject: %(Your character for "#{@project.name}" was rejected))
  end

  # Notifies the owner that an unused approval link expired before they acted.
  def approval_link_expired(approval_request)
    @approval_request = approval_request
    @project = approval_request.project
    @character = approval_request.character
    @user = approval_request.user
    @project_url = frontend_url("/projects/#{@project.id}/character")
    mail(to: @user.email, subject: %(Your character approval link for "#{@project.name}" expired))
  end

  private

  # Builds a link into the React public approval page for a raw token.
  def approval_url(raw_token, **query)
    frontend_url("/approvals/character/#{raw_token}", **query)
  end

  # Builds a link into the React app. Base URL is env-driven so links are correct
  # per environment.
  def frontend_url(path, **query)
    uri = URI.join(ENV.fetch("FRONTEND_URL", "http://localhost:5173"), path)
    uri.query = query.to_query if query.any?
    uri.to_s
  end
end
