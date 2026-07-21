module Api
  module V1
    module Admin
      # Email-delivery logs with full diagnostics + retry of a failed send.
      class EmailDeliveriesController < BaseController
        before_action :set_delivery, only: :retry

        # GET /api/v1/admin/email_deliveries?status=&email_type=&user_id=&page=&per_page=
        def index
          scope = EmailDelivery.order(created_at: :desc)
          scope = scope.where(status: params[:status]) if EmailDelivery.statuses.key?(params[:status])
          scope = scope.where(email_type: params[:email_type]) if params[:email_type].present?
          scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?

          records, meta = paginate(scope)
          render json: { email_deliveries: AdminEmailDeliveryBlueprint.render_as_hash(records), meta: meta }
        end

        # POST /api/v1/admin/email_deliveries/:id/retry
        def retry
          unless @delivery.failed? || @delivery.bounced?
            raise ::Admin::InvalidOperation, "Only a failed or bounced email can be retried"
          end

          RetryEmailDeliveryJob.perform_later(@delivery.id)
          audit!("email_delivery.retry", resource: @delivery, metadata: { email_type: @delivery.email_type })
          head :accepted
        end

        private

        def set_delivery
          @delivery = EmailDelivery.find(params[:id])
        end
      end
    end
  end
end
