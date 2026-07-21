# Emails the project owner that video generation has started.
class SendVideoGenerationStartedEmailJob < NotificationEmailJob
  def perform(video_id)
    video = Video.find_by(id: video_id)
    return if video.nil?

    Notifications::DeliverEmail.call(email_type: "video_generation_started", video: video)
  end
end
