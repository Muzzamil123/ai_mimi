module Api
  module V1
    module Webhooks
      # Public endpoint the video provider calls to report job status. There is no
      # user session; authenticity comes from the HMAC signature header, verified
      # before any work. Processing is handed to a background job so the provider
      # gets a fast 200 and retries/verification stay off the request path.
      class VideoGenerationsController < ActionController::API
        # Consistent JSON error envelope (this controller does not inherit the
        # authenticated BaseController).
        def create
          raw = request.raw_post
          signature = request.headers["X-Signature"] || request.headers["X-Webhook-Signature"]

          unless VideoGenerationProviders::WebhookVerifier.valid?(payload: raw, signature: signature)
            render json: error_body("invalid_signature", "Webhook signature verification failed"),
                   status: :unauthorized
            return
          end

          payload = parse(raw)
          if payload.nil?
            render json: error_body("invalid_payload", "Malformed webhook payload"), status: :bad_request
            return
          end

          HandleVideoGenerationWebhookJob.perform_later(payload)
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
