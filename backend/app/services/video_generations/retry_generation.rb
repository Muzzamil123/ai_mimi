module VideoGenerations
  # Retries a single failed variant: resets it to `pending` (keeping its
  # attempt_count history), moves the video back to `generating`, and re-submits.
  # The record is reused (never duplicated), preserving idempotency.
  class RetryGeneration < ApplicationService
    RETRYABLE_VIDEO_STATUSES = %w[generating partially_completed failed].freeze

    def initialize(video_generation, actor: nil)
      @generation = video_generation
      @video = video_generation.video
      @actor = actor
    end

    def call
      @video.with_lock do
        @generation.reload
        unless @generation.failed?
          raise VideoGenerations::InvalidState, "Only a failed output can be retried"
        end
        unless RETRYABLE_VIDEO_STATUSES.include?(@video.status)
          raise VideoGenerations::InvalidState, "This video's generation cannot be retried (#{@video.status})"
        end

        @generation.transition_to!(:pending, error_code: nil, error_message: nil)
        @video.transition_to!(:generating, actor: @actor, reason: "retrying failed output") unless @video.generating?
      end

      RetryVideoGenerationJob.perform_later(@generation.id)
      @generation
    end
  end
end
