module Videos
  # Runs the configured speech-to-text provider on a video's stored idea audio,
  # persists the transcript and provider metadata, and moves the video to
  # `idea_ready`. Called from TranscribeVideoIdeaJob within the idempotency guard,
  # so it assumes the video is the active transcription for this attempt.
  #
  # Kept separate from the job so the provider call and persistence can be unit
  # tested without Sidekiq, and so a different trigger could reuse it later.
  class TranscribeAudio < ApplicationService
    def initialize(video, storage_key: nil, mime_type: nil, storage: nil, provider: nil, actor: nil)
      @video = video
      @storage_key = storage_key || video.idea_audio_storage_key
      @mime_type = mime_type
      @storage = storage || Storage.adapter
      @provider = provider || SpeechToTextProviders.build
      @actor = actor
    end

    def call
      data = @storage.read(@storage_key)
      raise Storage::Error, "Idea audio missing from storage: #{@storage_key}" if data.nil?

      result = @provider.transcribe(
        audio_data: data,
        mime_type: @mime_type || inferred_mime_type,
        language: @video.language,
        filename: File.basename(@storage_key)
      )

      @video.update!(
        transcript: result.text,
        transcription_provider: result.provider,
        transcription_provider_model: result.model,
        transcription_provider_request_id: result.provider_request_id,
        transcription_cost: result.estimated_cost,
        transcription_failure_reason: nil
      )
      @video.transition_to!(:idea_ready, actor: @actor, reason: "audio transcribed")
      record_usage(result)
      @video
    end

    private

    # Ledger the billable transcription (Phase 12), keyed by the video so a
    # re-transcribe updates the same row.
    def record_usage(result)
      project = @video.project
      Usage::Record.call(
        source: @video,
        provider: result.provider,
        service_type: "speech_to_text",
        model: result.model,
        user: project&.user,
        project: project,
        video: @video,
        provider_request_id: result.provider_request_id,
        units: 1,
        provider_reported_cost: result.estimated_cost
      )
    end

    # Best-effort content type from the stored key's extension when the caller did
    # not pass one (e.g. a re-run that only has the key).
    def inferred_mime_type
      ext = File.extname(@storage_key).delete(".").downcase
      Videos::AUDIO_MIME_EXTENSIONS.key(ext) || "application/octet-stream"
    end
  end
end
