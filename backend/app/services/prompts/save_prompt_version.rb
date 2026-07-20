module Prompts
  # Saves a manually edited prompt as a new draft version (edit prompt / save new
  # version). Versions are immutable, so an edit never mutates an existing row —
  # it creates the next version and supersedes the prior working one, preserving
  # the full history for comparison. Allowed once a generated prompt exists
  # (video is `prompt_ready`).
  class SavePromptVersion < ApplicationService
    def initialize(video, content:, actor: nil)
      @video = video
      @content = content.to_s
      @actor = actor
    end

    def call
      if @content.strip.empty?
        raise Prompts::InvalidState, "Prompt content cannot be blank"
      end

      prompt = nil
      @video.with_lock do
        # Re-verify state under the lock (with_lock reloads the video) so a
        # concurrent regeneration can't leave the video in generating_prompt while
        # we supersede its in-flight version and strand it.
        unless @video.prompt_ready?
          raise Prompts::InvalidState, "Generate a prompt before editing one"
        end

        @video.prompts.where(status: %i[generating draft]).find_each do |working|
          working.transition_to!(:superseded)
        end
        prompt = @video.prompts.create!(
          version: (@video.prompts.maximum(:version) || 0) + 1,
          status: :draft,
          content: @content,
          provider: "manual",
          source_idea: @video.idea_source,
          created_by: @actor
        )
      end
      prompt
    end
  end
end
