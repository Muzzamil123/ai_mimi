require "net/http"
require "json"
require "base64"

module VideoGenerationProviders
  # Google Labs video-generation adapter. Google Labs has no official public API,
  # so this is a thin, REPLACEABLE HTTP integration against a configurable
  # endpoint (an internal gateway or a browser-automation service that exposes a
  # normalized HTTP surface — see docs/operations/google-labs-automation.md). It
  # is isolated from the core app behind this adapter, uses dedicated credentials
  # from the environment, never logs or returns them, and normalizes provider
  # responses into Result / StatusResult / Error. Without credentials it raises
  # NotConfigured (the deterministic Fake is used off-production instead).
  class GoogleLabs < Base
    DEFAULT_TIMEOUT = 60
    DEFAULT_MODEL = "google-labs-video".freeze
    # Per-15s-clip list price; overridable so cost tracking stays configuration.
    DEFAULT_COST_USD = 0.50

    # Maps provider-reported states to our normalized states.
    STATE_MAP = {
      "queued" => :processing,
      "pending" => :processing,
      "running" => :processing,
      "processing" => :processing,
      "in_progress" => :processing,
      "succeeded" => :completed,
      "success" => :completed,
      "completed" => :completed,
      "done" => :completed,
      "failed" => :failed,
      "error" => :failed,
      "cancelled" => :failed,
      "canceled" => :failed
    }.freeze

    def create_generation(prompt:, reference_image:, options: {})
      body = {
        prompt: prompt,
        model: model,
        duration_seconds: options[:duration_seconds] || Video::DEFAULT_DURATION_SECONDS,
        aspect_ratio: options[:aspect_ratio],
        variation: options[:variation_number],
        reference_image: encode_reference(reference_image)
      }.compact

      response = request(:post, "generations", body)
      payload = parse!(response)

      Result.new(
        provider_job_id: payload["id"] || payload["job_id"],
        provider_request_id: payload["request_id"],
        provider: "google_labs",
        model: payload["model"] || model,
        estimated_cost: estimated_cost
      )
    end

    def fetch_status(job_id:)
      response = request(:get, "generations/#{job_id}")
      payload = parse!(response)

      StatusResult.new(
        state: STATE_MAP.fetch(payload["status"].to_s, :processing),
        progress: payload["progress"],
        asset_ref: payload.dig("asset", "url") || payload["asset_url"],
        error_code: payload.dig("error", "code"),
        error_message: payload.dig("error", "message")
      )
    end

    def fetch_asset(job_id:)
      response = request(:get, "generations/#{job_id}/asset")
      unless response.code.to_i.between?(200, 299)
        raise Error.new("Asset fetch failed with status #{response.code}", retryable: retryable_status?(response.code.to_i))
      end

      { data: response.body, mime_type: response["Content-Type"] || "video/mp4" }
    end

    def model
      ENV.fetch("GOOGLE_LABS_MODEL", DEFAULT_MODEL)
    end

    private

    def encode_reference(reference_image)
      return nil if reference_image.nil?

      {
        mime_type: reference_image[:mime_type],
        data: Base64.strict_encode64(reference_image[:data].to_s)
      }
    end

    def request(method, path, body = nil)
      base = ENV["GOOGLE_LABS_API_BASE_URL"].to_s
      key = ENV["GOOGLE_LABS_API_KEY"].to_s
      raise NotConfigured if base.empty? || key.empty?

      uri = URI.join("#{base}/", path)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = timeout
      http.read_timeout = timeout

      request =
        case method
        when :post then Net::HTTP::Post.new(uri)
        else Net::HTTP::Get.new(uri)
        end
      request["Authorization"] = "Bearer #{key}"
      request["Content-Type"] = "application/json"
      if body
        request.body = JSON.generate(body)
      end

      http.request(request)
    rescue Net::OpenTimeout, Net::ReadTimeout
      raise TimeoutError
    rescue Errno::ECONNREFUSED, SocketError => e
      raise Error.new("Google Labs connection error: #{e.message}", retryable: true)
    end

    def parse!(response)
      code = response.code.to_i
      payload = safe_json(response.body)

      return payload if code.between?(200, 299)

      raise RateLimited if code == 429

      raise Error.new(
        payload.dig("error", "message") || "Google Labs request failed with status #{code}",
        retryable: retryable_status?(code),
        code: payload.dig("error", "code")
      )
    end

    def retryable_status?(code)
      code == 429 || code >= 500
    end

    def estimated_cost
      BigDecimal(ENV.fetch("GOOGLE_LABS_COST_USD", DEFAULT_COST_USD.to_s))
    end

    def safe_json(body)
      JSON.parse(body.to_s)
    rescue JSON::ParserError
      {}
    end

    def timeout
      Integer(ENV.fetch("GOOGLE_LABS_TIMEOUT_SECONDS", DEFAULT_TIMEOUT))
    rescue ArgumentError, TypeError
      DEFAULT_TIMEOUT
    end
  end
end
