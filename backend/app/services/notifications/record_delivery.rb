module Notifications
  # Records a tracking row for an email whose delivery is handled elsewhere (the
  # existing Phase 4/5 character emails, which carry an ephemeral token and are
  # sent via ActionMailer directly). This makes those events appear in the
  # notification center without changing their delivery path. Idempotent via
  # dedupe_key. Best-effort: never raises into the caller's workflow.
  class RecordDelivery < ApplicationService
    def initialize(user:, email_type:, dedupe_key:, project: nil, video: nil, subject: nil)
      @user = user
      @email_type = email_type.to_s
      @dedupe_key = dedupe_key
      @project = project
      @video = video
      @subject = subject
    end

    def call
      return if @user.nil? || @user.email.blank?

      EmailDelivery.find_or_create_by!(dedupe_key: @dedupe_key) do |delivery|
        delivery.user = @user
        delivery.project = @project
        delivery.video = @video
        delivery.email_type = @email_type
        delivery.recipient = @user.email
        delivery.subject = @subject.presence || Notifications.default_subject(@email_type)
        delivery.provider = Notifications.provider_name
        delivery.status = :sent
        delivery.sent_at = Time.current
      end
    rescue ActiveRecord::RecordNotUnique
      # A concurrent record won the unique dedupe_key; that's fine.
      EmailDelivery.find_by(dedupe_key: @dedupe_key)
    rescue StandardError => e
      Rails.logger.warn(message: "notification_tracking_failed", email_type: @email_type, detail: e.message)
      nil
    end
  end
end
