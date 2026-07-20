module VideoGenerations
  # Applies a normalized provider StatusResult to a processing variant: completes
  # it, fails it, or updates progress, and finalizes the video on a terminal
  # state. Shared by status polling and the webhook handler so both drive the
  # state machine through exactly one path. Idempotent: a no-op unless the record
  # is still `processing`.
  class ApplyStatus < ApplicationService
    def initialize(video_generation, status)
      @generation = video_generation
      @status = status
    end

    def call
      terminal = false

      # Row-lock the status flip so a concurrent poll and webhook for the same
      # variant can't lost-update each other (the in-memory status is re-read
      # under the lock). Finalize runs AFTER the row lock is released so we never
      # hold a generation-row lock while taking the video lock — that would invert
      # the video→generation ordering used by cancel and risk a deadlock.
      @generation.with_lock do
        next unless @generation.processing?

        if @status.completed?
          @generation.transition_to!(:completed)
          terminal = true
        elsif @status.failed?
          @generation.transition_to!(:failed,
                                     error_code: @status.error_code.presence || "provider_failed",
                                     error_message: @status.error_message)
          terminal = true
        elsif @status.progress
          @generation.update!(progress: @status.progress.to_i.clamp(0, 100))
        end
      end

      finalize if terminal
      @generation
    end

    private

    def finalize
      VideoGenerations::FinalizeVideo.call(@generation.video)
    end
  end
end
