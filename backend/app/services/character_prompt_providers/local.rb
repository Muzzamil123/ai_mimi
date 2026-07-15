module CharacterPromptProviders
  # Deterministic, dependency-free prompt builder. Used in development and test
  # so the character pipeline runs without an OpenAI key while still producing a
  # meaningful, descriptive prompt.
  class Local < Base
    def generate(character:, feedback: nil)
      sections = [
        "Create a single, consistent animated character reference image.",
        describe(character)
      ]
      sections << "Incorporate this revision feedback: #{feedback}" if feedback.present?
      sections << "Front-facing, clean neutral background, high detail, suitable as a reusable character reference."

      Result.new(
        prompt: sections.join("\n\n"),
        provider: "local",
        model: "local-template-1",
        provider_request_id: nil,
        prompt_tokens: nil,
        completion_tokens: nil,
        estimated_cost: BigDecimal("0")
      )
    end
  end
end
