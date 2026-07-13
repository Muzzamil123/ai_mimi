module Auth
  # Issues an access token (JWT) plus a rotating refresh token for a user.
  # The raw refresh token is returned once; only its digest is persisted.
  class IssueTokens < ApplicationService
    REFRESH_TTL = 30.days

    Tokens = Struct.new(:access_token, :refresh_token, :token_type, :expires_in, keyword_init: true)

    def initialize(user, request_context: {})
      @user = user
      @request_context = request_context
    end

    def call
      raw_refresh = SecureRandom.urlsafe_base64(48)

      @user.refresh_tokens.create!(
        token_digest: RefreshToken.digest(raw_refresh),
        expires_at: REFRESH_TTL.from_now,
        user_agent: @request_context[:user_agent],
        ip_address: @request_context[:ip_address]
      )

      Tokens.new(
        access_token: JsonWebToken.encode({ sub: @user.id, role: @user.role, type: "access" }),
        refresh_token: raw_refresh,
        token_type: "Bearer",
        expires_in: JsonWebToken::ACCESS_TTL.to_i
      )
    end
  end
end
