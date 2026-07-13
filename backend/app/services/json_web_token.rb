# Encodes/decodes short-lived access tokens (HS256 JWT). The signing secret is
# JWT_SECRET when set, otherwise the Rails secret_key_base.
class JsonWebToken
  ALGORITHM = "HS256"
  ACCESS_TTL = 15.minutes

  class << self
    def encode(payload, exp: ACCESS_TTL.from_now)
      claims = payload.merge(exp: exp.to_i, iat: Time.current.to_i, jti: SecureRandom.uuid)
      JWT.encode(claims, secret, ALGORITHM)
    end

    # Returns the claims as a HashWithIndifferentAccess, or nil if the token is
    # missing, tampered with, or expired (JWT::ExpiredSignature < JWT::DecodeError).
    def decode(token)
      return nil if token.blank?

      payload, = JWT.decode(token, secret, true, algorithm: ALGORITHM)
      payload.with_indifferent_access
    rescue JWT::DecodeError
      nil
    end

    private

    def secret
      ENV.fetch("JWT_SECRET") { Rails.application.secret_key_base }
    end
  end
end
