# Processes a verified provider webhook (signature checked at the controller).
# Looks up the variant by provider_job_id and applies the normalized status
# through the same VideoGenerations::ApplyStatus path as polling, so webhook and
# poll updates are consistent and idempotent.
#
# Expected payload keys: "job_id", "status" (processing|completed|failed),
# "progress", "error_code", "error_message".
class HandleVideoGenerationWebhookJob < ApplicationJob
  queue_as :ai_generation

  NORMALIZED_STATES = { "processing" => :processing, "completed" => :completed, "failed" => :failed }.freeze

  def perform(payload)
    payload = payload.with_indifferent_access
    job_id = payload[:job_id].presence || payload[:id].presence
    return if job_id.blank?

    generation = VideoGeneration.find_by(provider_job_id: job_id)
    return if generation.nil?

    state = NORMALIZED_STATES[payload[:status].to_s]
    return if state.nil?

    status = VideoGenerationProviders::StatusResult.new(
      state: state,
      progress: payload[:progress],
      error_code: payload[:error_code],
      error_message: payload[:error_message]
    )
    VideoGenerations::ApplyStatus.call(generation, status)
  end
end
