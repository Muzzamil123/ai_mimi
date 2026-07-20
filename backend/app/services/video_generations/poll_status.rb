module VideoGenerations
  # Polls the provider once for a processing variant and applies the normalized
  # status: updates progress while running, or moves the record to a terminal
  # state (completed/failed) and finalizes the video's aggregate status. Returns
  # the normalized StatusResult so the job can decide whether to poll again.
  # Idempotent: a no-op unless the record is still `processing`.
  class PollStatus < ApplicationService
    def initialize(video_generation, provider: nil)
      @generation = video_generation
      @provider = provider || VideoGenerationProviders.build
    end

    def call
      return unless @generation.processing?

      status = @provider.fetch_status(job_id: @generation.provider_job_id)
      VideoGenerations::ApplyStatus.call(@generation, status)
      status
    end

    # Marks the variant failed and finalizes the video. Used for terminal failures
    # discovered outside a normal status poll (e.g. a poll deadline timeout).
    # Row-locks the flip; finalizes after releasing the lock (see ApplyStatus).
    def fail!(code:, message:)
      failed = false
      @generation.with_lock do
        next unless @generation.processing? || @generation.pending?

        @generation.transition_to!(:failed, error_code: code, error_message: message)
        failed = true
      end
      finalize if failed
    end

    private

    def finalize
      VideoGenerations::FinalizeVideo.call(@generation.video)
    end
  end
end
