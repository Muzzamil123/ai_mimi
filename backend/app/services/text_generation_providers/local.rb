require "digest"

module TextGenerationProviders
  # Deterministic in-process provider for development and tests. Produces a
  # plausible, structured video prompt from the idea + context so the full
  # pipeline (generate, version, approve) runs end-to-end with no network or
  # credentials. Token counts are derived from the text so usage tracking has
  # realistic, stable values.
  class Local < Base
    def generate_video_prompt(idea:, context:, options: {})
      brief = context.to_brief
      content = build_prompt(idea, context)

      input_tokens = estimate_tokens(brief)
      output_tokens = estimate_tokens(content)

      Result.new(
        content: content,
        provider: "local",
        model: "local-prompt-1",
        provider_request_id: "local-#{Digest::SHA256.hexdigest(brief)[0, 12]}",
        input_tokens: input_tokens,
        output_tokens: output_tokens,
        estimated_cost: BigDecimal("0")
      )
    end

    private

    def build_prompt(idea, context)
      idea_text = idea.presence || "the character introduces itself"
      <<~PROMPT.strip
        #{context.duration_seconds}-second video featuring the project's approved character.
        Concept: #{idea_text}.
        Camera direction: steady medium shot, slow push-in.
        Visual direction: #{context.tone.presence || 'clean, vibrant'} styling suited to #{Array(context.target_platforms).join(', ').presence || 'social platforms'}.
        Character movement: natural, expressive gestures matching the concept.
        Dialogue: concise line delivered in #{context.language.presence || 'the target language'}.
        Audio style: upbeat background music with clear voice.
        Keep the character visually consistent with the reference and use the attached approved character image.
      PROMPT
    end

    # Rough token estimate (~4 chars/token) so the fake reports believable usage.
    def estimate_tokens(text)
      [ (text.to_s.length / 4.0).ceil, 1 ].max
    end
  end
end
