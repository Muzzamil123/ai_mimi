module Characters
  # Builds the image-generation prompt via the prompt provider (OpenAI in
  # production, Local otherwise) and persists it on the character. Any prior
  # rejection feedback guides the new prompt.
  class GeneratePrompt < ApplicationService
    def initialize(character, provider: nil)
      @character = character
      @provider = provider || CharacterPromptProviders.build
    end

    def call
      result = @provider.generate(character: @character, feedback: @character.rejection_feedback)
      @character.update!(generation_prompt: result.prompt)
      result
    end
  end
end
