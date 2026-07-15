# Provider abstraction for turning a text prompt into a character image. Every
# concrete provider (Gemini in production, Fake in dev/test) implements
# CharacterImageProviders::Base and returns a normalized Result, so the rest of
# the app never depends on a provider SDK or response shape.
module CharacterImageProviders
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
    def initialize(message = "Provider request timed out")
      super(message, retryable: true)
    end
  end

  # Normalized generation result. `image_data` is raw binary image bytes.
  Result = Struct.new(
    :image_data,
    :mime_type,
    :provider,
    :model,
    :provider_request_id,
    :provider_asset_id,
    :estimated_cost,
    keyword_init: true
  )

  class << self
    def build(name: default_provider)
      case name.to_s
      when "gemini"
        Gemini.new
      when "fake"
        Fake.new
      else
        raise Error, "Unknown character image provider: #{name}"
      end
    end

    # Real Gemini in production; the deterministic fake elsewhere so the app and
    # its test suite run without external credentials.
    def default_provider
      ENV.fetch("CHARACTER_IMAGE_PROVIDER", Rails.env.production? ? "gemini" : "fake")
    end
  end
end
