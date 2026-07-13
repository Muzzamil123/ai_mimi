module Api
  module V1
    module Auth
      # POST /api/v1/auth/password/forgot  and  POST /api/v1/auth/password/reset
      class PasswordsController < BaseController
        skip_authentication

        # Always 202 regardless of whether the email exists (no user enumeration).
        def forgot
          ::Auth::RequestPasswordReset.call(params[:email])
          head :accepted
        end

        def reset
          ::Auth::ResetPassword.call(params[:token], params[:password])
          head :no_content
        end
      end
    end
  end
end
