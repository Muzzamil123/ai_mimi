# Step 2 of the transcription pipeline: transcribe the stored idea audio with the
# configured speech-to-text provider and move the video to `idea_ready`.
class TranscribeVideoIdeaJob < Videos::TranscriptionJob
  def perform(video_id, transcription_id, storage_key, mime_type)
    with_active_transcription(video_id, transcription_id) do |video|
      Videos::TranscribeAudio.call(video, storage_key: storage_key, mime_type: mime_type)
    end
  end
end
