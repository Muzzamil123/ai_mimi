module VideoGenerations
  # Cancels an in-progress generation batch: marks every still-active variant
  # (pending/processing) cancelled and moves the video to `cancelled`. Completed
  # or already-failed variants are left as-is so their outcome is preserved.
  # Provider-side cancellation is best-effort and only where supported; the
  # local state is always made consistent.
  class CancelGeneration < ApplicationService
    CANCELLABLE_VIDEO_STATUSES = %w[queued generating partially_completed].freeze

    def initialize(video, actor: nil)
      @video = video
      @actor = actor
    end

    def call
      @video.with_lock do
        unless CANCELLABLE_VIDEO_STATUSES.include?(@video.status)
          raise VideoGenerations::InvalidState, "There is no active generation to cancel (#{@video.status})"
        end

        @video.video_generations.active.find_each do |generation|
          generation.transition_to!(:cancelled)
        end
        @video.transition_to!(:cancelled, actor: @actor, reason: "video generation cancelled")
      end
      @video
    end
  end
end
