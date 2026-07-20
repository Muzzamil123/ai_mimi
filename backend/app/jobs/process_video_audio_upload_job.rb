# Step 1 of the transcription pipeline: verify the uploaded idea audio was stored
# and is readable/non-empty, then hand off to transcription. Named "process"
# because this is where a future phase could normalize/transcode the audio; for
# now it validates the stored bytes so a bad upload fails fast before the
# (billable) provider call.
class ProcessVideoAudioUploadJob < Videos::TranscriptionJob
  def perform(video_id, transcription_id, storage_key, mime_type)
    with_active_transcription(video_id, transcription_id) do |_video|
      data = Storage.adapter.read(storage_key)
      raise Storage::Error, "Idea audio missing from storage: #{storage_key}" if data.nil? || data.empty?

      TranscribeVideoIdeaJob.perform_later(video_id, transcription_id, storage_key, mime_type)
    end
  end
end
