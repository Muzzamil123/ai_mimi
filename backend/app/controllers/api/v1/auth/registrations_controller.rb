module Api
  module V1
    module Auth
      # POST /api/v1/auth/register
      class RegistrationsController < BaseController
        skip_authentication

        def create
          user = ::Auth::RegisterUser.call(registration_params)
          tokens = ::Auth::IssueTokens.call(user, request_context: request_context)
          render_auth(user, tokens, status: :created)
        end

        private

        def registration_params
          params.require(:user).permit(:name, :email, :password)
        end
      end
    end
  end
end
