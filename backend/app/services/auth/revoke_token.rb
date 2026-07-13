module Auth
  # Revokes a refresh token (logout). Idempotent: unknown/blank tokens are a no-op
  # so logout never leaks whether a token existed.
  class RevokeToken < ApplicationService
    def initialize(raw_refresh_token)
      @raw = raw_refresh_token
    end

    def call
      return if @raw.blank?

      RefreshToken.find_by(token_digest: RefreshToken.digest(@raw))&.revoke!
    end
  end
end
