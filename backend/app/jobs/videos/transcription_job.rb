module Videos
  # Base class for the video transcription pipeline. Provides the shared
  # idempotency guard and provider/storage error handling so each concrete job
  # stays a thin, focused step. Mirrors Characters::GenerationJob.
  #
  # Idempotency: every job carries the video's `transcription_id`. A job only acts
  # while the video is still `transcribing` for that exact id, so duplicate,
  # out-of-order, or superseded jobs (e.g. after a re-upload) safely no-op.
  class TranscriptionJob < ApplicationJob
    queue_as :ai_generation

    # Transient provider/network failures are retried with backoff; when the
    # retries are exhausted the transcription is marked failed.
    retry_on Videos::TransientError, wait: :polynomially_longer, attempts: 5 do |job, error|
      video_id, transcription_id = job.arguments
      video = Video.find_by(id: video_id)
      next if video.nil?

      Videos::FailTranscription.call(
        video,
        transcription_id: transcription_id,
        reason: "transcription failed after retries: #{error.message}"
      )
    end

    private

    def with_active_transcription(video_id, transcription_id)
      video = Video.find_by(id: video_id)
      return if video.nil?
      return unless video.transcribing? && video.transcription_id == transcription_id

      yield video
    rescue SpeechToTextProviders::Error => e
      handle_failure(video, transcription_id, e.message, retryable: e.retryable)
    rescue Storage::Error => e
      handle_failure(video, transcription_id, e.message, retryable: false)
    rescue StandardError => e
      # Catch-all so an unexpected error (validation, DB, parse, bad config) can
      # never strand the video in `transcribing` with no recovery path. Mark the
      # transcription failed (the user can retry or type an idea) and log for ops.
      Rails.logger.error(
        message: "video_transcription_error",
        video_id: video&.id,
        error: e.class.name,
        detail: e.message
      )
      handle_failure(video, transcription_id, e.message, retryable: false)
    end

    def handle_failure(video, transcription_id, message, retryable:)
      if retryable
        # Re-raise so Sidekiq retries; status stays `transcribing` between attempts.
        raise Videos::TransientError, message
      else
        Videos::FailTranscription.call(video, transcription_id: transcription_id, reason: message)
      end
    end
  end
end
