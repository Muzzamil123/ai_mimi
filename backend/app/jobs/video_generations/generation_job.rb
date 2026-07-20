module VideoGenerations
  # Base class for the video-generation pipeline. Provides shared provider-error
  # handling and the submit step so the concrete jobs stay thin. Mirrors the
  # character/prompt/transcription pipelines.
  #
  # A retryable provider error (timeout, rate limit, 5xx) is retried with backoff;
  # on exhaustion — or on a permanent/unexpected error — the variant is marked
  # failed and the video is finalized, so a variant is never stranded in
  # `processing`.
  class GenerationJob < ApplicationJob
    queue_as :ai_generation

    retry_on VideoGenerations::TransientError, wait: :polynomially_longer, attempts: 8 do |job, error|
      generation = VideoGeneration.find_by(id: job.arguments.first)
      next if generation.nil?

      GenerationJob.fail_and_finalize(generation, code: "provider_failed",
                                                  message: "failed after retries: #{error.message}")
    end

    # Marks an active variant failed and finalizes its video. Class method so the
    # retry-exhaustion block can reuse it.
    def self.fail_and_finalize(generation, code:, message:)
      return unless generation.pending? || generation.processing?

      generation.transition_to!(:failed, error_code: code, error_message: message)
      VideoGenerations::FinalizeVideo.call(generation.video)
    end

    protected

    # Submits a variant to the provider and starts polling. Shared by
    # SubmitVideoGenerationJob (initial) and RetryVideoGenerationJob (retry).
    def submit(generation_id)
      guard(generation_id) do |generation|
        next unless generation.pending?

        VideoGenerations::SubmitGeneration.call(generation)
        PollVideoGenerationStatusJob.perform_later(generation.id)
      end
    end

    # Runs the block for a live generation, normalizing provider/unexpected errors
    # into a retry (transient) or a terminal failure (permanent).
    def guard(generation_id)
      generation = VideoGeneration.find_by(id: generation_id)
      return if generation.nil?

      yield generation
    rescue VideoGenerationProviders::Error => e
      handle_failure(generation, e.message, code: e.code, retryable: e.retryable)
    rescue StandardError => e
      Rails.logger.error(
        message: "video_generation_error",
        video_generation_id: generation&.id,
        error: e.class.name,
        detail: e.message
      )
      handle_failure(generation, e.message, code: "internal_error", retryable: false)
    end

    private

    def handle_failure(generation, message, code:, retryable:)
      if retryable
        raise VideoGenerations::TransientError, message
      else
        self.class.fail_and_finalize(generation, code: code || "provider_failed", message: message)
      end
    end
  end
end
