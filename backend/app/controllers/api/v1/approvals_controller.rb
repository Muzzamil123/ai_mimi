module Api
  module V1
    # Public, token-protected character-approval endpoints reached from the email
    # link. There is no logged-in user here — possession of the secure single-use
    # token IS the authorization, so authentication is skipped and Pundit is not
    # used. All business logic lives in the Approvals::* services.
    class ApprovalsController < BaseController
      include StreamsCharacterImage

      skip_authentication

      before_action :resolve_request

      # GET /api/v1/approvals/character/:token
      # Always renders the resolved state (pending/approved/rejected/expired) so
      # the page can show the right view. Unknown tokens 404 via ResolveToken.
      def show
        render json: ApprovalRequestBlueprint.render_as_hash(@approval_request)
      end

      # POST /api/v1/approvals/character/:token/approve
      def approve
        ::Approvals::ApproveViaToken.call(@approval_request)
        render json: ApprovalRequestBlueprint.render_as_hash(@approval_request.reload)
      end

      # POST /api/v1/approvals/character/:token/reject
      def reject
        ::Approvals::RejectViaToken.call(@approval_request, feedback: params[:feedback])
        render json: ApprovalRequestBlueprint.render_as_hash(@approval_request.reload)
      end

      # GET /api/v1/approvals/character/:token/image
      # Streams the character preview so the public page (and email clients) can
      # show it without an account. Token-gated like every action here.
      def image
        stream_character_image(@approval_request.character.latest_image)
      end

      private

      def resolve_request
        @approval_request = ::Approvals::ResolveToken.call(
          params[:token],
          request_context: request_context
        )
      end
    end
  end
end
