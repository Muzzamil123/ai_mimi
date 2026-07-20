module Prompts
  # Immutable, provider-agnostic bundle of everything a video prompt must be
  # grounded in. Assembled by Prompts::BuildContext and handed to a
  # TextGenerationProviders adapter. `#to_brief` renders a human-readable brief
  # for the model; structured fields remain available for other providers.
  Context = Struct.new(
    :character_description,
    :idea,
    :transcript,
    :language,
    :tone,
    :duration_seconds,
    :target_platforms,
    keyword_init: true
  ) do
    # Directions the generated prompt must cover (Phase 7 requirement).
    REQUIRED_DIRECTIONS = [
      "Camera direction",
      "Visual direction",
      "Character movement",
      "Dialogue",
      "Audio style"
    ].freeze

    def to_brief
      lines = []
      lines << "Character description: #{character_description}" if character_description.present?
      lines << "Video idea: #{idea}" if idea.present?
      lines << "Spoken/transcribed idea: #{transcript}" if transcript.present?
      lines << "Language: #{language}" if language.present?
      lines << "Tone: #{tone}" if tone.present?
      lines << "Duration: #{duration_seconds} seconds"
      lines << "Target platforms: #{Array(target_platforms).join(', ')}" if target_platforms.present?
      lines << ""
      lines << "The prompt must explicitly address each of: #{REQUIRED_DIRECTIONS.join(', ')}."
      lines << "It must instruct the video model to keep the character visually " \
               "consistent with the description and to use the attached approved " \
               "character reference image."
      lines.join("\n")
    end
  end
end
