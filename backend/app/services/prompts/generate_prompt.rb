require "securerandom"

module Prompts
  # Starts (or restarts) AI prompt generation for a video. Creates a new version
  # in `generating`, supersedes any prior working (non-approved) version, moves
  # the video to `generating_prompt`, and enqueues the async pipeline. A rotating
  # generation_id supersedes in-flight jobs from a previous attempt (idempotency),
  # mirroring character generation. Regeneration is just another call — it always
  # produces a fresh version, keeping the full history.
  class GeneratePrompt < ApplicationService
    STARTABLE_VIDEO_STATUSES = %w[idea_ready prompt_ready failed].freeze

    def initialize(video, actor: nil)
      @video = video
      @actor = actor
    end

    def call
      unless @video.idea_present?
        raise Prompts::InvalidState, "Add an idea (typed or spoken) before generating a prompt"
      end

      generation_id = SecureRandom.uuid
      first_version = nil
      prompt = nil

      @video.with_lock do
        # Re-verify status under the lock (with_lock reloads the video) so a
        # concurrent generate/approve/save can't race past the check; the loser
        # gets the friendly "already in progress" message rather than a raw
        # transition error.
        unless STARTABLE_VIDEO_STATUSES.include?(@video.status)
          raise Prompts::InvalidState, startable_error_message
        end

        first_version = @video.prompts.none?
        supersede_working_versions!
        prompt = @video.prompts.create!(
          version: next_version,
          status: :generating,
          generation_id: generation_id,
          source_idea: @video.idea_source,
          created_by: @actor
        )
        @video.transition_to!(:generating_prompt, actor: @actor, reason: "prompt generation started")
      end

      enqueue(prompt, generation_id, first_version)
      prompt
    end

    private

    def startable_error_message
      if @video.generating_prompt?
        "Prompt generation is already in progress"
      else
        "A prompt cannot be generated for this video in its current state (#{@video.status})"
      end
    end

    # Retire the current working version (an in-flight generation or an
    # unapproved draft) so only one working version exists at a time. An approved
    # version stays active until a new one is approved.
    def supersede_working_versions!
      @video.prompts.where(status: %i[generating draft]).find_each do |working|
        working.transition_to!(:superseded)
      end
    end

    def next_version
      (@video.prompts.maximum(:version) || 0) + 1
    end

    def enqueue(prompt, generation_id, first_version)
      job = first_version ? GenerateVideoPromptJob : RegenerateVideoPromptJob
      job.perform_later(prompt.id, generation_id)
    end
  end
end
