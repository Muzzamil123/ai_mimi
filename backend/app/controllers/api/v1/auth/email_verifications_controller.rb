module Api
  module V1
    module Auth
      # POST /api/v1/auth/email/verify
      class EmailVerificationsController < BaseController
        skip_authentication

        def create
          ::Auth::VerifyEmail.call(params[:token])
          head :no_content
        end
      end
    end
  end
end
