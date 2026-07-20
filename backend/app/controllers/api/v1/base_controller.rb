module Api
  module V1
    # Base controller for all versioned API endpoints. Provides token
    # authentication, Pundit authorization, the auth response helper, and a
    # consistent JSON error envelope: { "error": { "code", "messages" } }.
    class BaseController < ApplicationController
      include Authenticatable
      include Pundit::Authorization
      include TokenResponder

      rescue_from ActiveRecord::RecordInvalid do |e|
        render_error(:unprocessable_entity, "validation_failed", e.record.errors.full_messages)
      end

      rescue_from ActiveRecord::RecordNotFound do
        render_error(:not_found, "not_found", "Resource not found")
      end

      rescue_from ActiveRecord::RecordNotUnique do
        render_error(:unprocessable_entity, "conflict", "That record already exists; please retry")
      end

      rescue_from ActionController::ParameterMissing do |e|
        render_error(:unprocessable_entity, "parameter_missing", e.message)
      end

      rescue_from Pundit::NotAuthorizedError do
        render_error(:forbidden, "forbidden", "You are not permitted to perform this action")
      end

      rescue_from ::Auth::AuthenticationError do |e|
        render_error(:unauthorized, "unauthorized", e.message)
      end

      rescue_from ::Projects::InvalidTransition do |e|
        render_error(:unprocessable_entity, "invalid_transition", e.message)
      end

      rescue_from ::Characters::InvalidTransition do |e|
        render_error(:unprocessable_entity, "invalid_transition", e.message)
      end

      rescue_from ::Characters::InvalidState do |e|
        render_error(:unprocessable_entity, "invalid_state", e.message)
      end

      rescue_from ::Videos::InvalidTransition do |e|
        render_error(:unprocessable_entity, "invalid_transition", e.message)
      end

      rescue_from ::Videos::InvalidState do |e|
        render_error(:unprocessable_entity, "invalid_state", e.message)
      end

      rescue_from ::Videos::InvalidAudio do |e|
        render_error(:unprocessable_entity, "invalid_audio", e.message)
      end

      rescue_from ::Prompts::InvalidTransition do |e|
        render_error(:unprocessable_entity, "invalid_transition", e.message)
      end

      rescue_from ::Prompts::InvalidState do |e|
        render_error(:unprocessable_entity, "invalid_state", e.message)
      end

      rescue_from ::VideoGenerations::InvalidTransition do |e|
        render_error(:unprocessable_entity, "invalid_transition", e.message)
      end

      rescue_from ::VideoGenerations::InvalidState do |e|
        render_error(:unprocessable_entity, "invalid_state", e.message)
      end

      rescue_from ::Approvals::InvalidToken do |e|
        render_error(:not_found, "invalid_token", e.message)
      end

      rescue_from ::Approvals::LinkExpired do |e|
        render_error(:gone, "link_expired", e.message)
      end

      rescue_from ::Approvals::AlreadyProcessed do |e|
        render_error(:conflict, "already_processed", e.message)
      end

      private

      def render_error(status, code, messages)
        render json: { error: { code: code, messages: Array(messages) } }, status: status
      end
    end
  end
end
