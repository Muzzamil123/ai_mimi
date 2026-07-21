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
          user = ::Auth::ResetPassword.call(params[:token], params[:password])
          ::Audit::Record.call(
            actor: user, action: "auth.password_reset", resource: user, request_context: request_context
          )
          head :no_content
        end
      end
    end
  end
end
