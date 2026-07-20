module Prompts
  # Marks an in-flight prompt generation as failed (prompt -> failed, video ->
  # failed) recording the reason. Guarded by generation_id so a late failure from
  # a superseded attempt cannot clobber a newer one. Idempotent: a no-op unless
  # the prompt is currently generating for this generation_id.
  class FailGeneration < ApplicationService
    def initialize(prompt, generation_id:, reason:, actor: nil)
      @prompt = prompt
      @generation_id = generation_id
      @reason = reason
      @actor = actor
    end

    def call
      return if @prompt.nil?
      return unless @prompt.generating? && @prompt.generation_id == @generation_id

      video = @prompt.video
      @prompt.transaction do
        @prompt.update!(failure_reason: @reason.to_s.truncate(255))
        @prompt.transition_to!(:failed)
        video.transition_to!(:failed, actor: @actor, reason: "prompt generation failed") if video.generating_prompt?
      end
      @prompt
    end
  end
end
