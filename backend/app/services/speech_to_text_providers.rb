# Provider abstraction for transcribing a spoken video idea into text. Per the
# platform's provider rules, speech transcription is OpenAI's responsibility; the
# deterministic Fake provider is the default in dev/test so the pipeline runs
# without credentials. The rest of the app never depends on a provider SDK or
# response shape — it only sees a normalized Result / Error.
module SpeechToTextProviders
  # Base class for provider failures. `retryable` distinguishes transient issues
  # (timeouts, 5xx, rate limits) from permanent ones (bad request, auth) so jobs
  # can decide whether to retry.
  class Error < StandardError
    attr_reader :retryable

    def initialize(message = nil, retryable: false)
      super(message)
      @retryable = retryable
    end
  end

  class TimeoutError < Error
    def initialize(message = "Transcription provider request timed out")
      super(message, retryable: true)
    end
  end

  # Normalized transcription result. `text` is the transcript handed back to the
  # video; the remaining fields feed cost/usage tracking.
  Result = Struct.new(
    :text,
    :language,
    :provider,
    :model,
    :provider_request_id,
    :duration_seconds,
    :estimated_cost,
    keyword_init: true
  )

  class << self
    def build(name: default_provider)
      case name.to_s
      when "openai"
        OpenAI.new
      when "fake"
        Fake.new
      else
        raise Error, "Unknown speech-to-text provider: #{name}"
      end
    end

    # Real OpenAI transcription in production; the deterministic fake elsewhere so
    # the app and its test suite run without external credentials.
    def default_provider
      ENV.fetch("SPEECH_TO_TEXT_PROVIDER", Rails.env.production? ? "openai" : "fake")
    end
  end
end
