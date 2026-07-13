module Api
  module V1
    # GET/PATCH/DELETE /api/v1/me — the authenticated user's own account.
    class CurrentUserController < BaseController
      def show
        render json: UserBlueprint.render_as_hash(current_user)
      end

      def update
        attrs = update_params
        current_user.update!(attrs)
        # A password change invalidates all existing sessions (defence in depth).
        current_user.refresh_tokens.active.find_each(&:revoke!) if attrs[:password].present?
        render json: UserBlueprint.render_as_hash(current_user)
      end

      # Account-deletion request: soft-delete and revoke all sessions.
      def destroy
        current_user.transaction do
          current_user.refresh_tokens.active.find_each(&:revoke!)
          current_user.update!(status: :deleted)
        end
        head :no_content
      end

      private

      def update_params
        attrs = params.require(:user).permit(:name, :password, :current_password)

        if attrs[:password].present?
          unless current_user.authenticate(attrs[:current_password])
            raise ::Auth::AuthenticationError, "Current password is incorrect"
          end

          attrs.slice(:name, :password)
        else
          attrs.slice(:name)
        end
      end
    end
  end
end
