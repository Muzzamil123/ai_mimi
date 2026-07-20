require "cgi"

module Downloads
  # Mints and verifies short-lived, tamper-proof download tokens using Rails'
  # message verifier (HMAC + built-in expiry). A token encodes what may be served
  # (an asset's video or thumbnail, or an archive storage key) and for how long,
  # so the streaming endpoint needs no session — the token is the authorization.
  # Tokens travel as a URL-encoded query parameter so their base64 payload is safe
  # in any URL.
  module SignedUrl
    PURPOSE = "asset_download".freeze
    DEFAULT_TTL_SECONDS = 3600
    ENDPOINT = "/api/v1/downloads".freeze

    class InvalidToken < StandardError; end

    class << self
      def asset_path(asset, disposition: "attachment", expires_in: default_ttl)
        path(kind: "asset", asset_id: asset.id, disposition: disposition, expires_in: expires_in)
      end

      def thumbnail_path(asset, expires_in: default_ttl)
        path(kind: "thumbnail", asset_id: asset.id, disposition: "inline", expires_in: expires_in)
      end

      def archive_path(storage_key, filename:, expires_in: default_ttl)
        path(kind: "archive", storage_key: storage_key, filename: filename,
             disposition: "attachment", expires_in: expires_in)
      end

      # Returns the decoded payload Hash, or raises InvalidToken if the token is
      # tampered or expired.
      def verify(raw)
        verifier.verify(raw.to_s, purpose: PURPOSE).with_indifferent_access
      rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveSupport::MessageEncryptor::InvalidMessage
        raise InvalidToken, "Invalid or expired download link"
      end

      private

      def path(expires_in:, **payload)
        token = verifier.generate(payload, purpose: PURPOSE, expires_in: expires_in)
        "#{ENDPOINT}?token=#{CGI.escape(token)}"
      end

      def verifier
        Rails.application.message_verifier(:asset_downloads)
      end

      def default_ttl
        Integer(ENV.fetch("DOWNLOAD_URL_TTL_SECONDS", DEFAULT_TTL_SECONDS))
      rescue ArgumentError, TypeError
        DEFAULT_TTL_SECONDS
      end
    end
  end
end
