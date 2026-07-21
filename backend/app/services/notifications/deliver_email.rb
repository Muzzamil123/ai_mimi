module Notifications
  # The robust delivery path for video-workflow emails: resolves the recipient
  # from the project owner's CURRENT account email, honours the owner's
  # preferences, prevents duplicates (one email per event via dedupe_key),
  # tracks the EmailDelivery, and sends. A failed send marks the record failed
  # and re-raises so the job (or RetryEmailDeliveryJob) can retry — a retry reuses
  # the same record, so duplicate prevention still holds.
  class DeliverEmail < ApplicationService
    def initialize(email_type:, video:, dedupe_key: nil)
      @email_type = email_type.to_s
      @video = video
      @project = video&.project
      @user = @project&.user
      @dedupe_key = dedupe_key || default_dedupe_key
    end

    def call
      return if @user.nil? || @user.email.blank?
      return unless @user.email_type_enabled?(@email_type)

      delivery = @dedupe_key ? EmailDelivery.find_by(dedupe_key: @dedupe_key) : nil
      # Already queued/sent/delivered for this event — don't send again.
      return delivery if delivery && !delivery.failed?

      delivery ||= EmailDelivery.new(
        user: @user, project: @project, video: @video,
        email_type: @email_type, recipient: @user.email,
        provider: Notifications.provider_name, dedupe_key: @dedupe_key
      )
      deliver!(delivery)
      delivery
    end

    private

    def deliver!(delivery)
      mail = Notifications::MailFactory.build(email_type: @email_type, video: @video)
      raise Notifications::Error, "No mail builder for #{@email_type}" if mail.nil?

      delivery.assign_attributes(
        recipient: @user.email, subject: mail.subject, status: :queued, error_message: nil
      )
      delivery.save!

      # At-least-once: if delivery succeeds but the status update below fails, the
      # record stays `queued` and a retry is short-circuited by the non-failed
      # dedupe check in #call — so the rare crash-after-send does not re-send.
      mail.deliver_now
      delivery.update!(status: :sent, sent_at: Time.current, provider_message_id: mail.message_id)
    rescue StandardError => e
      delivery.update!(status: :failed, error_message: e.message.to_s.truncate(1000)) if delivery.persisted?
      raise
    end

    # One email per event: keyed by type + video + the approved prompt, so a fresh
    # generation run (new approved prompt) re-notifies but a retry/duplicate does not.
    def default_dedupe_key
      return nil if @video.nil?

      "#{@email_type}:#{@video.id}:#{@video.active_prompt_id}"
    end
  end
end
