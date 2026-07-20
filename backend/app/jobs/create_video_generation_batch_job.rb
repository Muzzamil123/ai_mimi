# Creates the four generation records for a video and kicks off submission.
# Idempotent via VideoGenerations::CreateBatch (find_or_create by idempotency_key).
class CreateVideoGenerationBatchJob < ApplicationJob
  queue_as :ai_generation

  def perform(video_id)
    video = Video.find_by(id: video_id)
    return if video.nil?

    VideoGenerations::CreateBatch.call(video)
  end
end
