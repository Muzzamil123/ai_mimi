module Characters
  # Base class for the character generation pipeline. Provides the shared
  # idempotency guard and provider/storage error handling so each concrete job
  # stays a thin, focused step.
  #
  # Idempotency: every job carries the character's `generation_id`. A job only
  # acts while the character is still `generating` for that exact id, so
  # duplicate, out-of-order, or superseded jobs (e.g. after a reset or a newer
  # regeneration) safely no-op.
  class GenerationJob < ApplicationJob
    queue_as :ai_generation

    # Transient provider/network failures are retried with backoff; when the
    # retries are exhausted the generation is marked failed.
    retry_on Characters::TransientError, wait: :polynomially_longer, attempts: 5 do |job, error|
      character_id, generation_id = job.arguments
      character = Character.find_by(id: character_id)
      next if character.nil?

      Characters::FailGeneration.call(
        character,
        generation_id: generation_id,
        reason: "generation failed after retries: #{error.message}"
      )
    end

    private

    def with_active_generation(character_id, generation_id)
      character = Character.find_by(id: character_id)
      return if character.nil?
      return unless character.generating? && character.generation_id == generation_id

      yield character
    rescue CharacterImageProviders::Error, CharacterPromptProviders::Error => e
      handle_failure(character, generation_id, e.message, retryable: e.retryable)
    rescue Storage::Error => e
      handle_failure(character, generation_id, e.message, retryable: false)
    rescue StandardError => e
      # Catch-all so an unexpected error (validation, DB, parse, bad config) can
      # never strand the character in `generating` with no recovery path. Mark
      # the generation failed (the user can then regenerate) and log for ops.
      Rails.logger.error(
        message: "character_generation_error",
        character_id: character&.id,
        error: e.class.name,
        detail: e.message
      )
      handle_failure(character, generation_id, e.message, retryable: false)
    end

    def handle_failure(character, generation_id, message, retryable:)
      if retryable
        # Re-raise so Sidekiq retries; status stays `generating` between attempts.
        raise Characters::TransientError, message
      else
        Characters::FailGeneration.call(character, generation_id: generation_id, reason: message)
      end
    end
  end
end
