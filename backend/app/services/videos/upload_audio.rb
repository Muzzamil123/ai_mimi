require "securerandom"

module Videos
  # Accepts a spoken idea: validates the uploaded audio, stores the raw bytes via
  # the storage abstraction (synchronously, so the request owns the upload), then
  # starts the asynchronous transcription pipeline. A fresh `transcription_id` is
  # minted on every upload so any in-flight jobs from a previous attempt are
  # superseded and safely no-op (idempotency), mirroring character generation.
  class UploadAudio < ApplicationService
    STARTABLE_STATUSES = %w[draft idea_ready transcribing failed].freeze

    def initialize(video, file:, storage: nil, actor: nil)
      @video = video
      @file = file
      @storage = storage || Storage.adapter
      @actor = actor
    end

    def call
      validate_state!
      data, mime_type = read_and_validate_file!

      previous_key = @video.idea_audio_storage_key
      transcription_id = SecureRandom.uuid
      extension = Videos.audio_extension_for(mime_type)
      storage_key = "videos/#{@video.id}/idea-audio/#{transcription_id}.#{extension}"

      @storage.store(key: storage_key, data: data, content_type: mime_type)

      @video.transaction do
        @video.update!(
          transcription_id: transcription_id,
          idea_audio_storage_key: storage_key,
          transcription_failure_reason: nil
        )
        # From `transcribing` a re-upload stays in `transcribing`; otherwise move
        # into it. Recording history each time keeps the audit trail complete.
        @video.transition_to!(:transcribing, actor: @actor, reason: "audio uploaded") unless @video.transcribing?
      end

      # Reclaim the superseded blob from a prior attempt so re-uploads/retries
      # don't leave orphaned audio behind. Best-effort, after the commit so a
      # rolled-back transaction never deletes the old key.
      @storage.delete(previous_key) if previous_key.present? && previous_key != storage_key

      ProcessVideoAudioUploadJob.perform_later(@video.id, transcription_id, storage_key, mime_type)
      @video
    end

    private

    def validate_state!
      return if STARTABLE_STATUSES.include?(@video.status)

      raise Videos::InvalidState, "Audio cannot be uploaded for a video in its current state (#{@video.status})"
    end

    # Extracts bytes + content type from an ActionDispatch uploaded file (or any
    # object responding to #read / #content_type) and enforces type and size.
    def read_and_validate_file!
      raise Videos::InvalidAudio, "No audio file was provided" if @file.nil?

      mime_type = extract_mime_type(@file)
      unless Videos.supported_audio_type?(mime_type)
        raise Videos::InvalidAudio, "Unsupported audio type: #{mime_type.presence || 'unknown'}"
      end

      data = read_bytes(@file)
      raise Videos::InvalidAudio, "The audio file is empty" if data.blank?

      if Videos.looks_like_non_audio?(data)
        raise Videos::InvalidAudio, "The uploaded file does not appear to be audio"
      end

      max = Videos.max_audio_bytes
      if data.bytesize > max
        raise Videos::InvalidAudio, "Audio file is too large (max #{max / (1024 * 1024)} MB)"
      end

      [ data, normalize_mime(mime_type) ]
    end

    def extract_mime_type(file)
      if file.respond_to?(:content_type)
        file.content_type.to_s
      else
        ""
      end
    end

    def read_bytes(file)
      if file.respond_to?(:read)
        file.rewind if file.respond_to?(:rewind)
        file.read
      else
        file.to_s
      end
    end

    def normalize_mime(mime_type)
      mime_type.to_s.split(";").first.to_s.strip.downcase
    end
  end
end
