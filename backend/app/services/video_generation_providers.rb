# Provider abstraction for generating videos. Per the platform's provider rules,
# video generation is Google Labs' responsibility; the deterministic Fake is the
# default in dev/test so the pipeline runs without credentials. The rest of the
# app only ever sees normalized Result / StatusResult / Error values — never a
# provider SDK, HTTP shape, or credential.
module VideoGenerationProviders
  # Base class for provider failures. `retryable` distinguishes transient issues
  # (timeouts, 5xx, rate limits) from permanent ones so jobs can decide whether
  # to retry.
  class Error < StandardError
    attr_reader :retryable, :code

    def initialize(message = nil, retryable: false, code: nil)
      super(message)
      @retryable = retryable
      @code = code
    end
  end

  class TimeoutError < Error
    def initialize(message = "Video provider request timed out")
      super(message, retryable: true, code: "timeout")
    end
  end

  class RateLimited < Error
    def initialize(message = "Video provider rate limit exceeded")
      super(message, retryable: true, code: "rate_limited")
    end
  end

  # Raised by a real adapter that has no credentials/API configured.
  class NotConfigured < Error
    def initialize(message = "Video generation provider is not configured")
      super(message, retryable: false, code: "not_configured")
    end
  end

  # Result of create_generation: the accepted provider job to poll.
  Result = Struct.new(
    :provider_job_id,
    :provider_request_id,
    :provider,
    :model,
    :estimated_cost,
    keyword_init: true
  )

  # Normalized job status. `state` is one of :processing, :completed, :failed.
  # `asset_ref` (for a completed job) is an opaque handle the download step
  # (Phase 9) passes to fetch_asset.
  StatusResult = Struct.new(
    :state,
    :progress,
    :asset_ref,
    :error_code,
    :error_message,
    keyword_init: true
  ) do
    def processing? = state.to_sym == :processing
    def completed? = state.to_sym == :completed
    def failed? = state.to_sym == :failed
  end

  class << self
    def build(name: default_provider)
      case name.to_s
      when "google_labs"
        GoogleLabs.new
      when "fake"
        Fake.new
      else
        raise Error, "Unknown video generation provider: #{name}"
      end
    end

    # Real Google Labs in production; the deterministic fake elsewhere so the app
    # and its test suite run without external credentials.
    def default_provider
      ENV.fetch("VIDEO_GENERATION_PROVIDER", Rails.env.production? ? "google_labs" : "fake")
    end
  end
end
