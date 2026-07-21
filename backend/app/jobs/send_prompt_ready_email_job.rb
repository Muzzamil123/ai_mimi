# Emails the project owner that a video's prompt has been generated and is ready
# to review. Optional (owner can disable in preferences).
class SendPromptReadyEmailJob < NotificationEmailJob
  def perform(video_id)
    video = Video.find_by(id: video_id)
    return if video.nil?

    Notifications::DeliverEmail.call(email_type: "prompt_ready", video: video)
  end
end
