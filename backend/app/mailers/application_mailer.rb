class ApplicationMailer < ActionMailer::Base
  # Resolved per-message so an admin can change the sender identity via platform
  # settings without a redeploy. Falls back to ENV/the historical default when no
  # setting is configured, so existing behaviour is preserved.
  default from: -> { ApplicationMailer.resolved_from }
  layout "mailer"

  def self.resolved_from
    address = PlatformSetting.get("email_from_address").presence
    return ENV.fetch("MAIL_FROM", "AI Character Video Platform <no-reply@aicvp.local>") if address.nil?

    name = PlatformSetting.get("email_sender_name").presence
    name ? "#{name} <#{address}>" : address
  end
end
