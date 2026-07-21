module Notifications
  # Builds the ActionMailer Mail for a video-workflow email type from its video.
  # Because the mail is rebuildable from the persisted associations, a failed
  # delivery can be retried simply by rebuilding here. Character emails are NOT
  # built here — they carry an ephemeral single-use token and are delivered by the
  # existing Phase 4/5 code (only tracked via Notifications::RecordDelivery).
  class MailFactory
    def self.build(email_type:, video:)
      return nil if video.nil?

      case email_type.to_s
      when "prompt_ready" then UserMailer.prompt_ready(video)
      when "video_generation_started" then UserMailer.video_generation_started(video)
      when "video_generation_completed" then UserMailer.video_generation_completed(video)
      when "video_generation_partially_completed" then UserMailer.video_generation_partially_completed(video)
      when "video_generation_failed" then UserMailer.video_generation_failed(video)
      end
    end
  end
end
