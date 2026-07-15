module CharacterImageProviders
  # Interface implemented by every character-image provider.
  class Base
    # Generates an image from +prompt+. +options+ may carry style preferences
    # and provider-specific hints. Returns a CharacterImageProviders::Result and
    # raises CharacterImageProviders::Error (or ::TimeoutError) on failure.
    def generate(prompt:, options: {})
      raise NotImplementedError
    end
  end
end
