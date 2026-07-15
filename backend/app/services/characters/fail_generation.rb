module Characters
  # Marks an in-flight generation as failed (character -> failed, project ->
  # failed) recording the reason. Guarded by generation_id so a late failure from
  # a superseded attempt cannot clobber a newer one. Idempotent: a no-op unless
  # the character is currently generating for this generation_id.
  class FailGeneration < ApplicationService
    def initialize(character, generation_id:, reason:, actor: nil)
      @character = character
      @generation_id = generation_id
      @reason = reason
      @actor = actor
    end

    def call
      return if @character.nil?
      return unless @character.generating? && @character.generation_id == @generation_id

      @character.update!(failure_reason: @reason.to_s.truncate(255))
      @character.transition_to!(:failed, actor: @actor, reason: "generation failed")
      @character
    end
  end
end
