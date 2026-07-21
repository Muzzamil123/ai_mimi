# Namespace for notification/email delivery service objects. Every workflow email
# is tracked as an EmailDelivery and always sent to the project owner's current
# account email (mandatory business rule — never a hardcoded recipient).
module Notifications
  class Error < StandardError; end

  # Generic subjects for tracking-only rows (character emails, whose Mail is built
  # and delivered by the existing Phase 4/5 code). Video emails use the real
  # Mail#subject captured at send time.
  SUBJECTS = {
    "character_ready" => "Your character is ready for approval",
    "character_approved" => "Your character was approved",
    "character_rejected" => "Your character was rejected",
    "approval_link_expired" => "Your character approval link expired"
  }.freeze

  def self.default_subject(email_type)
    SUBJECTS[email_type.to_s] || email_type.to_s.humanize
  end

  # Human-facing email provider name recorded on each delivery.
  def self.provider_name
    ENV.fetch("EMAIL_PROVIDER", "letter_opener")
  end
end
