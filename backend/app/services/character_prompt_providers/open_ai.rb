require "net/http"
require "json"

module CharacterPromptProviders
  # OpenAI Chat Completions adapter. Asks the model to turn the character's
  # descriptive fields into a vivid image-generation prompt. Talks HTTP directly
  # (no vendor SDK) and normalizes the response/errors. This is the only place
  # OpenAI's request/response shape is known.
  class OpenAI < Base
    include Providers::Breakable

    DEFAULT_BASE_URL = "https://api.openai.com".freeze
    DEFAULT_MODEL = "gpt-4o-mini".freeze
    DEFAULT_TIMEOUT = 30
    # Blended USD cost per 1K tokens; overridable via env for cost tracking.
    DEFAULT_COST_PER_1K = 0.001

    SYSTEM_PROMPT = <<~TEXT.freeze
      You are a prompt engineer for an image-generation model. Given a character
      brief, write a single richly detailed prompt that will produce one
      consistent, front-facing animated character reference image. Return only the
      prompt text, no preamble or explanation.
    TEXT

    def generate(character:, feedback: nil)
      response = post(chat_body(character, feedback))
      parse(response)
    rescue Net::OpenTimeout, Net::ReadTimeout
      raise TimeoutError
    rescue Providers::CircuitOpenError => e
      raise Error.new(e.message, retryable: true)
    rescue Errno::ECONNREFUSED, SocketError => e
      raise Error.new("OpenAI connection error: #{e.message}", retryable: true)
    end

    def parse(response)
      code = response.code.to_i
      payload = safe_json(response.body)

      unless code.between?(200, 299)
        raise Error.new(error_message(payload, code), retryable: retryable_status?(code))
      end

      content = payload.dig("choices", 0, "message", "content").to_s.strip
      raise Error.new("OpenAI returned an empty prompt", retryable: true) if content.empty?

      usage = payload["usage"] || {}
      prompt_tokens = usage["prompt_tokens"]
      completion_tokens = usage["completion_tokens"]

      Result.new(
        prompt: content,
        provider: "openai",
        model: payload["model"] || model,
        provider_request_id: payload["id"],
        prompt_tokens: prompt_tokens,
        completion_tokens: completion_tokens,
        estimated_cost: estimate_cost(usage["total_tokens"])
      )
    end

    def model
      ENV.fetch("OPENAI_PROMPT_MODEL", DEFAULT_MODEL)
    end

    private

    def chat_body(character, feedback)
      user_content = [ describe(character) ]
      user_content << "Revision feedback to address: #{feedback}" if feedback.present?

      {
        model: model,
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user", content: user_content.join("\n\n") }
        ]
      }
    end

    def post(body)
      key = Providers::Credentials.fetch("openai_api_key", env: "OPENAI_API_KEY").to_s
      raise Error.new("OpenAI API key is not configured", retryable: false) if key.empty?

      uri = URI.join("#{base_url}/", "v1/chat/completions")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = timeout
      http.read_timeout = timeout

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{key}"
      request.body = JSON.generate(body)

      with_circuit("character_prompt:openai") { http.request(request) }
    end

    def error_message(payload, code)
      payload.dig("error", "message") || "OpenAI request failed with status #{code}"
    end

    def retryable_status?(code)
      code == 429 || code >= 500
    end

    def estimate_cost(total_tokens)
      return nil if total_tokens.nil?

      per_1k = BigDecimal(ENV.fetch("OPENAI_COST_PER_1K_TOKENS", DEFAULT_COST_PER_1K.to_s))
      (per_1k * total_tokens / 1000).round(6)
    end

    def safe_json(body)
      JSON.parse(body.to_s)
    rescue JSON::ParserError
      {}
    end

    def base_url
      ENV.fetch("OPENAI_API_BASE_URL", DEFAULT_BASE_URL)
    end

    def timeout
      Integer(ENV.fetch("OPENAI_TIMEOUT_SECONDS", DEFAULT_TIMEOUT))
    rescue ArgumentError, TypeError
      DEFAULT_TIMEOUT
    end
  end
end
