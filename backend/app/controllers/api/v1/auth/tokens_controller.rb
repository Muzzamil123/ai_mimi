module Api
  module V1
    module Auth
      # POST /api/v1/auth/refresh
      class TokensController < BaseController
        skip_authentication

        def create
          result = ::Auth::RefreshTokens.call(params[:refresh_token], request_context: request_context)
          render_auth(result.user, result.tokens)
        end
      end
    end
  end
end
