module Api
  module V1
    # The owner's email notification preferences: which optional email types they
    # receive. Mandatory types (approval, completion/failure results) are always
    # on and not listed here.
    class NotificationPreferencesController < BaseController
      # GET /api/v1/me/notification_preferences
      def show
        render json: preferences_payload
      end

      # PATCH /api/v1/me/notification_preferences
      def update
        current_user.update_notification_preferences!(preference_params.to_h)
        render json: preferences_payload
      end

      private

      def preferences_payload
        optional = EmailDelivery::OPTIONAL_TYPES.index_with do |type|
          current_user.email_type_enabled?(type)
        end
        { optional_email_types: EmailDelivery::OPTIONAL_TYPES, preferences: optional }
      end

      def preference_params
        params.fetch(:preferences, {}).permit(*EmailDelivery::OPTIONAL_TYPES)
      end
    end
  end
end
