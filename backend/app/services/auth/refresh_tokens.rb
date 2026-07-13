module Auth
  # Validates a refresh token, rotates it (single-use), and issues a fresh pair.
  # Raises InvalidTokenError or AccountInactive.
  class RefreshTokens < ApplicationService
    Result = Struct.new(:user, :tokens, keyword_init: true)

    def initialize(raw_refresh_token, request_context: {})
      @raw = raw_refresh_token
      @request_context = request_context
    end

    def call
      raise InvalidTokenError, "Invalid refresh token" if @raw.blank?

      record = RefreshToken.find_by(token_digest: RefreshToken.digest(@raw))
      raise InvalidTokenError, "Invalid refresh token" unless record&.active?

      user = record.user
      raise AccountInactive, "This account is #{user.status}" unless user.status_active?

      record.revoke! # rotation: the presented token is now spent
      Result.new(user: user, tokens: IssueTokens.call(user, request_context: @request_context))
    end
  end
end
