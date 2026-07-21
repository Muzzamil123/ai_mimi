require "openssl"

module Notifications
  # Verifies the HMAC-SHA256 signature on an inbound email-provider delivery
  # webhook so only the provider can drive delivery-status updates. The shared
  # secret comes from the environment and is never logged. Constant-time compare.
  class WebhookVerifier
    def self.secret
      ENV["EMAIL_WEBHOOK_SECRET"].to_s
    end

    def self.valid?(payload:, signature:)
      key = secret
      return false if key.empty? || signature.to_s.empty?

      expected = OpenSSL::HMAC.hexdigest("SHA256", key, payload.to_s)
      ActiveSupport::SecurityUtils.secure_compare(expected, signature.to_s)
    end
  end
end
