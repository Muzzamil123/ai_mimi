module Api
  module V1
    module Webhooks
      # Public endpoint the email provider calls to report delivery status
      # (delivered / bounced / failed). No session — authenticity comes from the
      # HMAC signature header. Processing is handed to a background job.
      class EmailDeliveriesController < ActionController::API
        def create
          raw = request.raw_post
          signature = request.headers["X-Signature"] || request.headers["X-Webhook-Signature"]

          unless Notifications::WebhookVerifier.valid?(payload: raw, signature: signature)
            render json: error_body("invalid_signature", "Webhook signature verification failed"),
                   status: :unauthorized
            return
          end

          payload = parse(raw)
          if payload.nil?
            render json: error_body("invalid_payload", "Malformed webhook payload"), status: :bad_request
            return
          end

          HandleEmailDeliveryWebhookJob.perform_later(payload)
          head :accepted
        end

        private

        def parse(raw)
          JSON.parse(raw)
        rescue JSON::ParserError
          nil
        end

        def error_body(code, message)
          { error: { code: code, messages: [ message ] } }
        end
      end
    end
  end
end
