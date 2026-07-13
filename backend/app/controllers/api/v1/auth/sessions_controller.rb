module Api
  module V1
    module Auth
      # POST /api/v1/auth/login  and  POST /api/v1/auth/logout
      class SessionsController < BaseController
        skip_authentication

        def create
          user = ::Auth::AuthenticateUser.call(params[:email], params[:password])
          tokens = ::Auth::IssueTokens.call(user, request_context: request_context)
          render_auth(user, tokens)
        end

        def destroy
          ::Auth::RevokeToken.call(params[:refresh_token])
          head :no_content
        end
      end
    end
  end
end
