# Emails the project owner the outcome of a generation run, choosing the email
# type from the video's terminal status (completed / partially_completed /
# failed). A no-op for a non-terminal video.
class SendVideoCompletionEmailJob < NotificationEmailJob
  EMAIL_TYPE_FOR = {
    "completed" => "video_generation_completed",
    "partially_completed" => "video_generation_partially_completed",
    "failed" => "video_generation_failed"
  }.freeze

  def perform(video_id)
    video = Video.find_by(id: video_id)
    return if video.nil?

    email_type = EMAIL_TYPE_FOR[video.status]
    return if email_type.nil?

    Notifications::DeliverEmail.call(email_type: email_type, video: video)
  end
end
