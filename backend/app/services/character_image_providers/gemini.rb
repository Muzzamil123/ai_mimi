require "net/http"
require "json"
require "base64"

module CharacterImageProviders
  # Google Gemini image-generation adapter. Talks to the Generative Language
  # `:generateContent` endpoint over HTTP (no vendor SDK) and normalizes the
  # response and errors into CharacterImageProviders::Result / ::Error. This is
  # the only place Gemini's request/response shape is known.
  class Gemini < Base
    DEFAULT_BASE_URL = "https://generativelanguage.googleapis.com".freeze
    DEFAULT_MODEL = "gemini-2.5-flash-image".freeze
    DEFAULT_TIMEOUT = 60
    # Per-image list price; overridable so cost tracking stays configuration, not
    # a magic number baked into code.
    DEFAULT_COST_USD = 0.039

    def generate(prompt:, options: {})
      body = request_body(prompt, options)
      response = post(body)
      parse(response)
    rescue Net::OpenTimeout, Net::ReadTimeout
      raise TimeoutError
    rescue Errno::ECONNREFUSED, SocketError => e
      raise Error.new("Gemini connection error: #{e.message}", retryable: true)
    end

    # Parses a raw HTTP response into a Result. Extracted so response handling
    # can be unit-tested without a live endpoint.
    def parse(response)
      code = response.code.to_i
      payload = safe_json(response.body)

      unless code.between?(200, 299)
        raise Error.new(error_message(payload, code), retryable: retryable_status?(code))
      end

      part = image_part(payload)
      raise Error.new("Gemini returned no image", retryable: true) if part.nil?

      Result.new(
        image_data: Base64.decode64(part.dig("inlineData", "data").to_s),
        mime_type: part.dig("inlineData", "mimeType") || "image/png",
        provider: "gemini",
        model: payload["modelVersion"] || model,
        provider_request_id: payload["responseId"],
        provider_asset_id: payload["responseId"],
        estimated_cost: cost_per_image
      )
    end

    def model
      ENV.fetch("GEMINI_IMAGE_MODEL", DEFAULT_MODEL)
    end

    private

    def request_body(prompt, options)
      full_prompt = [ prompt, style_hint(options) ].compact.join("\n\n")
      {
        contents: [ { parts: [ { text: full_prompt } ] } ],
        generationConfig: { responseModalities: [ "IMAGE" ] }
      }
    end

    def style_hint(options)
      prefs = options[:style_preferences] || options["style_preferences"]
      return nil if prefs.blank?

      "Style preferences: #{prefs.is_a?(Hash) ? prefs.map { |k, v| "#{k}: #{v}" }.join(', ') : prefs}"
    end

    def post(body)
      key = ENV["GEMINI_API_KEY"].to_s
      raise Error.new("GEMINI_API_KEY is not configured", retryable: false) if key.empty?

      uri = URI.join("#{base_url}/", "v1beta/models/#{model}:generateContent")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = timeout
      http.read_timeout = timeout

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["x-goog-api-key"] = key
      request.body = JSON.generate(body)

      http.request(request)
    end

    def image_part(payload)
      parts = payload.dig("candidates", 0, "content", "parts") || []
      parts.find { |part| part.is_a?(Hash) && part["inlineData"].present? }
    end

    def error_message(payload, code)
      payload.dig("error", "message") || "Gemini request failed with status #{code}"
    end

    def retryable_status?(code)
      code == 429 || code >= 500
    end

    def safe_json(body)
      JSON.parse(body.to_s)
    rescue JSON::ParserError
      {}
    end

    def base_url
      ENV.fetch("GEMINI_API_BASE_URL", DEFAULT_BASE_URL)
    end

    def timeout
      Integer(ENV.fetch("GEMINI_TIMEOUT_SECONDS", DEFAULT_TIMEOUT))
    end

    def cost_per_image
      BigDecimal(ENV.fetch("GEMINI_IMAGE_COST_USD", DEFAULT_COST_USD.to_s))
    end
  end
end
