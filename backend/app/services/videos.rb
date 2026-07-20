# Namespace for video workspace service objects and their errors (Phase 6:
# typed/spoken ideas and speech transcription).
module Videos
  # Raised when a video status transition is not permitted by its state machine.
  class InvalidTransition < StandardError; end

  # Raised when an operation is attempted on a video in an incompatible state
  # (e.g. creating a video before the project's character is approved, editing a
  # video while it is being transcribed).
  class InvalidState < StandardError; end

  # Raised when an uploaded audio file is missing, too large, or of an
  # unsupported type.
  class InvalidAudio < StandardError; end

  # Signals a transient transcription failure that Sidekiq should retry. On
  # exhaustion the transcription is marked failed (see Videos::TranscriptionJob).
  class TransientError < StandardError; end

  # Audio types accepted for a spoken idea, mapped to the extension used for the
  # storage key. Covers the common browser-recorder and upload formats.
  AUDIO_MIME_EXTENSIONS = {
    "audio/webm" => "webm",
    "audio/ogg" => "ogg",
    "audio/mpeg" => "mp3",
    "audio/mp3" => "mp3",
    "audio/mp4" => "m4a",
    "audio/m4a" => "m4a",
    "audio/x-m4a" => "m4a",
    "audio/wav" => "wav",
    "audio/x-wav" => "wav",
    "audio/wave" => "wav"
  }.freeze

  DEFAULT_MAX_AUDIO_BYTES = 25 * 1024 * 1024 # 25 MB (OpenAI transcription limit).

  def self.audio_extension_for(mime_type)
    AUDIO_MIME_EXTENSIONS.fetch(mime_type.to_s.split(";").first.to_s.strip.downcase, "bin")
  end

  def self.supported_audio_type?(mime_type)
    AUDIO_MIME_EXTENSIONS.key?(mime_type.to_s.split(";").first.to_s.strip.downcase)
  end

  def self.max_audio_bytes
    Integer(ENV.fetch("VIDEO_AUDIO_MAX_BYTES", DEFAULT_MAX_AUDIO_BYTES.to_s))
  rescue ArgumentError, TypeError
    DEFAULT_MAX_AUDIO_BYTES
  end

  # Leading-byte signatures of common non-audio formats. Used to reject a file
  # whose bytes are clearly not audio even when the client claims an audio
  # Content-Type (defence against spoofing). This is a lightweight sanity check;
  # deeper upload restrictions (full magic-byte/AV scanning) are Phase 13.
  NON_AUDIO_SIGNATURES = [
    "%PDF".b,          # PDF
    "\x89PNG".b,       # PNG
    "GIF8".b,          # GIF
    "\xFF\xD8\xFF".b,  # JPEG
    "PK\x03\x04".b,    # ZIP / Office documents
    "\x7FELF".b,       # ELF executable
    "MZ".b,            # Windows executable
    "<!DOCTYPE".b,     # HTML
    "<html".b          # HTML
  ].freeze

  def self.looks_like_non_audio?(data)
    head = data.to_s.byteslice(0, 16).to_s.b
    NON_AUDIO_SIGNATURES.any? { |signature| head.start_with?(signature) }
  end
end
