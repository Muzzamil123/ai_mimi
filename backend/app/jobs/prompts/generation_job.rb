module Prompts
  # Base class for the prompt generation pipeline. Provides the shared idempotency
  # guard and provider error handling so the concrete jobs stay thin. Mirrors
  # Characters::GenerationJob / Videos::TranscriptionJob.
  #
  # Idempotency: every job carries the prompt's `generation_id`. It only acts
  # while the prompt is still `generating` for that exact id, so duplicate,
  # out-of-order, or superseded jobs (e.g. after a regeneration) safely no-op.
  #
  # Concrete subclasses (GenerateVideoPromptJob, RegenerateVideoPromptJob) exist
  # as distinct, observable entry points for first-time vs. repeat generation but
  # share this identical behaviour — no logic is duplicated.
  class GenerationJob < ApplicationJob
    queue_as :ai_generation

    retry_on Prompts::TransientError, wait: :polynomially_longer, attempts: 5 do |job, error|
      prompt_id, generation_id = job.arguments
      prompt = Prompt.find_by(id: prompt_id)
      next if prompt.nil?

      Prompts::FailGeneration.call(
        prompt,
        generation_id: generation_id,
        reason: "prompt generation failed after retries: #{error.message}"
      )
    end

    def perform(prompt_id, generation_id)
      prompt = Prompt.find_by(id: prompt_id)
      return if prompt.nil?
      return unless prompt.generating? && prompt.generation_id == generation_id

      Prompts::GenerateContent.call(prompt)
    rescue TextGenerationProviders::Error => e
      handle_failure(prompt, generation_id, e.message, retryable: e.retryable)
    rescue StandardError => e
      # Catch-all so an unexpected error (validation, DB, parse, bad config) can
      # never strand the prompt in `generating` / the video in `generating_prompt`
      # with no recovery path. Mark it failed (the user can regenerate) and log.
      Rails.logger.error(
        message: "prompt_generation_error",
        prompt_id: prompt&.id,
        error: e.class.name,
        detail: e.message
      )
      handle_failure(prompt, generation_id, e.message, retryable: false)
    end

    private

    def handle_failure(prompt, generation_id, message, retryable:)
      if retryable
        # Re-raise so Sidekiq retries; status stays `generating` between attempts.
        raise Prompts::TransientError, message
      else
        Prompts::FailGeneration.call(prompt, generation_id: generation_id, reason: message)
      end
    end
  end
end
