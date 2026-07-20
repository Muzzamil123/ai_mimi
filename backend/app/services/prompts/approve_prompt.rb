module Prompts
  # Approves a draft prompt version: marks it `approved`, supersedes every other
  # live version, and points the video's active_prompt at it. The approved prompt
  # is what automated video generation (Phase 8) will use. Idempotent enough that
  # re-approving the already-active prompt is a no-op.
  class ApprovePrompt < ApplicationService
    def initialize(prompt, actor: nil)
      @prompt = prompt
      @video = prompt.video
      @actor = actor
    end

    def call
      # All preconditions are re-verified inside the lock against freshly reloaded
      # state: with_lock (SELECT ... FOR UPDATE) serializes with a concurrent
      # regenerate/save on the same video, so a stale in-memory status can't slip
      # through and strand the video (e.g. superseding an in-flight generation).
      @video.with_lock do
        @prompt.reload

        # Idempotent: re-approving the already-active prompt is a no-op.
        unless @prompt.approved? && @video.active_prompt_id == @prompt.id
          unless @prompt.draft?
            raise Prompts::InvalidState, "Only a draft prompt can be approved"
          end
          unless @video.prompt_ready?
            raise Prompts::InvalidState, "The video is not ready for prompt approval"
          end

          # Retire every other live version so exactly one is active.
          @video.prompts.live.where.not(id: @prompt.id).find_each do |other|
            other.transition_to!(:superseded)
          end
          @prompt.transition_to!(:approved)
          @video.update!(active_prompt_id: @prompt.id)
        end
      end

      @prompt
    end
  end
end
