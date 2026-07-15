module CharacterPromptProviders
  # Interface implemented by every character-prompt provider.
  class Base
    # Builds an image-generation prompt for +character+ (optionally guided by the
    # user's rejection +feedback+ on a prior attempt). Returns a
    # CharacterPromptProviders::Result; raises ::Error / ::TimeoutError on failure.
    def generate(character:, feedback: nil)
      raise NotImplementedError
    end

    protected

    # Shared, human-readable summary of the character used by every provider.
    def describe(character)
      lines = []
      lines << "Name: #{character.name}"
      lines << "Description: #{character.description}" if character.description.present?

      attrs = character.character_attributes.presence
      lines << "Attributes: #{attrs.map { |k, v| "#{k}: #{v}" }.join(', ')}" if attrs

      styles = character.style_preferences.presence
      lines << "Style preferences: #{styles.map { |k, v| "#{k}: #{v}" }.join(', ')}" if styles

      lines.join("\n")
    end
  end
end
