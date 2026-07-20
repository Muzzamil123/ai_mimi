require "net/http"
require "json"
require "securerandom"

module SpeechToTextProviders
  # OpenAI audio-transcription adapter. Posts the audio as multipart/form-data to
  # the `/v1/audio/transcriptions` endpoint over HTTP (no vendor SDK) and
  # normalizes the response/errors. This is the only place OpenAI's transcription
  # request/response shape is known.
  class OpenAI < Base
    DEFAULT_BASE_URL = "https://api.openai.com".freeze
    DEFAULT_MODEL = "whisper-1".freeze
    DEFAULT_TIMEOUT = 120
    # USD cost per audio minute; overridable via env so cost tracking stays
    # configuration, not a magic number baked into code.
    DEFAULT_COST_PER_MINUTE = 0.006

    def transcribe(audio_data:, mime_type:, language: nil, filename: nil)
      raise Error.new("Cannot transcribe empty audio", retryable: false) if audio_data.to_s.empty?

      response = post(audio_data, mime_type, language, filename)
      parse(response, language)
    rescue Net::OpenTimeout, Net::ReadTimeout
      raise TimeoutError
    rescue Errno::ECONNREFUSED, SocketError => e
      raise Error.new("OpenAI connection error: #{e.message}", retryable: true)
    end

    # Parses a raw HTTP response into a Result. Extracted so response handling can
    # be unit-tested without a live endpoint.
    def parse(response, language = nil)
      code = response.code.to_i
      payload = safe_json(response.body)

      unless code.between?(200, 299)
        raise Error.new(error_message(payload, code), retryable: retryable_status?(code))
      end

      text = payload["text"].to_s.strip
      raise Error.new("OpenAI returned an empty transcript", retryable: true) if text.empty?

      duration = payload["duration"]

      Result.new(
        text: text,
        language: language,
        provider: "openai",
        model: payload["model"] || model,
        provider_request_id: response["x-request-id"],
        duration_seconds: duration&.to_f,
        estimated_cost: estimate_cost(duration)
      )
    end

    def model
      ENV.fetch("OPENAI_TRANSCRIBE_MODEL", DEFAULT_MODEL)
    end

    private

    def post(audio_data, mime_type, language, filename)
      key = ENV["OPENAI_API_KEY"].to_s
      raise Error.new("OPENAI_API_KEY is not configured", retryable: false) if key.empty?

      uri = URI.join("#{base_url}/", "v1/audio/transcriptions")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = timeout
      http.read_timeout = timeout

      boundary = "----aicvp#{SecureRandom.hex(16)}"
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{key}"
      request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
      request.body = multipart_body(boundary, audio_data, mime_type, language, filename)

      http.request(request)
    end

    def multipart_body(boundary, audio_data, mime_type, language, filename)
      name = filename.presence || "idea-audio.#{Videos.audio_extension_for(mime_type)}"
      parts = []

      parts << field(boundary, "model", model)
      parts << field(boundary, "response_format", "verbose_json")
      iso = iso_language(language)
      parts << field(boundary, "language", iso) if iso

      parts << +"--#{boundary}\r\n"
      parts << %(Content-Disposition: form-data; name="file"; filename="#{name}"\r\n)
      parts << "Content-Type: #{mime_type}\r\n\r\n"

      body = parts.join.b
      body << audio_data.b
      body << "\r\n--#{boundary}--\r\n".b
      body
    end

    def field(boundary, name, value)
      "--#{boundary}\r\nContent-Disposition: form-data; name=\"#{name}\"\r\n\r\n#{value}\r\n"
    end

    def error_message(payload, code)
      payload.dig("error", "message") || "OpenAI transcription failed with status #{code}"
    end

    def retryable_status?(code)
      code == 429 || code >= 500
    end

    def estimate_cost(duration_seconds)
      return nil if duration_seconds.nil?

      per_minute = BigDecimal(ENV.fetch("OPENAI_TRANSCRIBE_COST_PER_MINUTE", DEFAULT_COST_PER_MINUTE.to_s))
      (per_minute * BigDecimal(duration_seconds.to_s) / 60).round(6)
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
      Integer(ENV.fetch("OPENAI_TRANSCRIBE_TIMEOUT_SECONDS", DEFAULT_TIMEOUT))
    rescue ArgumentError, TypeError
      DEFAULT_TIMEOUT
    end
  end
end
