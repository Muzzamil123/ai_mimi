module VideoGenerations
  # Aggregates the current batch's variant statuses into the video's status once
  # every variant is terminal: all completed -> completed; some completed ->
  # partially_completed; none completed -> failed. Runs under the video lock and
  # only while the video is mid-generation, so concurrent variant completions
  # converge to one consistent result.
  class FinalizeVideo < ApplicationService
    def initialize(video)
      @video = video
    end

    def call
      finalized = false

      @video.with_lock do
        next unless @video.generating? || @video.partially_completed?

        batch = current_batch
        next if batch.empty? || batch.any? { |g| !g.terminal? }

        completed = batch.count(&:completed?)
        target =
          if completed == batch.size
            :completed
          elsif completed.positive?
            :partially_completed
          else
            :failed
          end

        unless @video.status == target.to_s
          @video.transition_to!(target, reason: "video generation #{target}")
          finalized = true
        end
      end

      # Email the outcome (post-commit, exactly once — only the finalizing call).
      SendVideoCompletionEmailJob.perform_later(@video.id) if finalized
    end

    private

    # The variants for the video's current approved prompt (this generation
    # request), reloaded inside the lock.
    def current_batch
      @video.video_generations.where(prompt_id: @video.active_prompt_id).to_a
    end
  end
end
