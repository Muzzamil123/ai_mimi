require "openssl"

module VideoGenerationProviders
  # Verifies the HMAC-SHA256 signature on an inbound video-generation webhook so
  # only the provider can drive status updates. The shared secret comes from the
  # environment and is never logged. Uses a constant-time comparison to avoid
  # timing attacks.
  class WebhookVerifier
    def self.secret
      ENV["GOOGLE_LABS_WEBHOOK_SECRET"].to_s
    end

    # Returns true when +signature+ (hex HMAC-SHA256 of the raw +payload+ body
    # under the configured secret) is valid. Returns false if no secret is
    # configured or the signature is missing/mismatched.
    def self.valid?(payload:, signature:)
      key = secret
      return false if key.empty? || signature.to_s.empty?

      expected = OpenSSL::HMAC.hexdigest("SHA256", key, payload.to_s)
      ActiveSupport::SecurityUtils.secure_compare(expected, signature.to_s)
    end
  end
end
