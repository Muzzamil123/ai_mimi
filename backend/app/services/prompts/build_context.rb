module Prompts
  # Assembles the Prompts::Context for a video from the video, its project, and
  # the project's approved character. Centralizing this keeps prompt grounding in
  # one place and out of the providers/jobs (which stay provider-only). The
  # approved character's description anchors visual consistency across every
  # video in the project.
  class BuildContext < ApplicationService
    def initialize(video)
      @video = video
      @project = video.project
    end

    def call
      Context.new(
        character_description: character_description,
        idea: @video.idea_text,
        transcript: @video.transcript,
        language: @video.language,
        tone: @video.tone,
        duration_seconds: @video.duration_seconds,
        target_platforms: @project.target_platforms
      )
    end

    private

    # Description of the project's approved character (the reference the video
    # must stay consistent with). Falls back gracefully if attributes are absent.
    def character_description
      character = @project.active_character || @project.character
      return nil if character.nil?

      parts = []
      parts << character.name if character.name.present?
      parts << character.description if character.description.present?

      attrs = character.character_attributes.presence
      parts << attrs.map { |k, v| "#{k}: #{v}" }.join(", ") if attrs

      parts.compact.join(". ").presence
    end
  end
end
