require "securerandom"

module Characters
  # Starts (or restarts) the character generation pipeline. Valid from `pending`
  # (initial generation) and from `rejected`/`failed` (regeneration). Rotating
  # the generation_id supersedes any in-flight jobs from a previous attempt, so
  # duplicate/stale jobs no-op. Enqueues the first job and lets the pipeline run
  # asynchronously.
  class GenerateCharacter < ApplicationService
    STARTABLE_STATUSES = %w[pending rejected failed].freeze

    def initialize(character, actor: nil)
      @character = character
      @actor = actor
    end

    def call
      if @character.approved?
        raise Characters::InvalidState, "An approved character is locked and cannot be regenerated"
      end

      unless STARTABLE_STATUSES.include?(@character.status)
        raise Characters::InvalidState, "Generation is already in progress"
      end

      generation_id = SecureRandom.uuid
      @character.transaction do
        @character.update!(generation_id: generation_id, provider_job_id: nil)
        @character.transition_to!(:generating, actor: @actor, reason: "generation started")
      end

      GenerateCharacterPromptJob.perform_later(@character.id, generation_id)
      @character
    end
  end
end
