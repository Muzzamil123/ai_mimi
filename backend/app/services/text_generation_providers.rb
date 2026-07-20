# Provider abstraction for generating a production-ready *video* prompt from a
# video's idea. Per the platform's provider rules, prompt generation is OpenAI's
# responsibility; the deterministic Local provider is the default in dev/test so
# the pipeline runs without credentials. The rest of the app never depends on a
# provider SDK or response shape — it only sees a normalized Result / Error.
module TextGenerationProviders
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
    def initialize(message = "Text generation provider request timed out")
      super(message, retryable: true)
    end
  end

  # Normalized generation result. `content` is the prompt text; the remaining
  # fields feed usage/cost tracking.
  Result = Struct.new(
    :content,
    :provider,
    :model,
    :provider_request_id,
    :input_tokens,
    :output_tokens,
    :estimated_cost,
    keyword_init: true
  )

  class << self
    def build(name: default_provider)
      case name.to_s
      when "openai"
        OpenAI.new
      when "local"
        Local.new
      else
        raise Error, "Unknown text generation provider: #{name}"
      end
    end

    # Real OpenAI in production; the deterministic local provider elsewhere so the
    # app and its test suite run without external credentials.
    def default_provider
      ENV.fetch("TEXT_GENERATION_PROVIDER", Rails.env.production? ? "openai" : "local")
    end
  end
end
