module Api
  module V1
    # The authenticated owner's notification center: a feed of their tracked
    # workflow emails, with unread count, mark-as-read, and retry of a failed
    # delivery. Always scoped to current_user — a user only sees their own.
    class NotificationsController < BaseController
      include Paginatable

      before_action :set_notification, only: :retry

      # GET /api/v1/notifications?unread=true&page=&per_page=
      def index
        scope = current_user.email_deliveries.recent
        scope = scope.unread if ActiveModel::Type::Boolean.new.cast(params[:unread])

        records, meta = paginate(scope)
        meta[:unread_count] = current_user.email_deliveries.unread.count
        render json: { notifications: EmailDeliveryBlueprint.render_as_hash(records), meta: meta }
      end

      # POST /api/v1/notifications/read  ({ ids: [...] } or all when omitted)
      def read
        scope = current_user.email_deliveries.unread
        scope = scope.where(id: params[:ids]) if params[:ids].present?
        scope.update_all(read_at: Time.current)
        render json: { unread_count: current_user.email_deliveries.unread.count }
      end

      # POST /api/v1/notifications/:id/retry
      def retry
        unless @notification.failed?
          raise ::Notifications::Error, "Only a failed notification can be retried"
        end

        RetryEmailDeliveryJob.perform_later(@notification.id)
        head :accepted
      end

      private

      def set_notification
        @notification = current_user.email_deliveries.find(params[:id])
      end
    end
  end
end
