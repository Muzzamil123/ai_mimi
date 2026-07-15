# Provider abstraction for composing the image-generation *prompt* from a
# character's descriptive fields. Per the platform's provider rules, prompt
# generation is OpenAI's responsibility; the deterministic Local provider is the
# default in dev/test so the pipeline runs without credentials. The image itself
# is produced separately by CharacterImageProviders.
module CharacterPromptProviders
  class Error < StandardError
    attr_reader :retryable

    def initialize(message = nil, retryable: false)
      super(message)
      @retryable = retryable
    end
  end

  class TimeoutError < Error
    def initialize(message = "Prompt provider request timed out")
      super(message, retryable: true)
    end
  end

  # Normalized prompt result. `prompt` is the text handed to the image provider.
  Result = Struct.new(
    :prompt,
    :provider,
    :model,
    :provider_request_id,
    :prompt_tokens,
    :completion_tokens,
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
        raise Error, "Unknown character prompt provider: #{name}"
      end
    end

    def default_provider
      ENV.fetch("CHARACTER_PROMPT_PROVIDER", Rails.env.production? ? "openai" : "local")
    end
  end
end
