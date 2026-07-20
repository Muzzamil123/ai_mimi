module TextGenerationProviders
  # Interface implemented by every video-prompt provider.
  class Base
    # Builds a production-ready video-generation prompt from +idea+ (the video's
    # typed/transcribed idea) and +context+ (a Prompts::Context carrying the
    # character description, language, tone, duration, direction hints, target
    # platforms, and consistency instructions). Returns a
    # TextGenerationProviders::Result; raises ::Error / ::TimeoutError on failure.
    def generate_video_prompt(idea:, context:, options: {})
      raise NotImplementedError
    end

    protected

    # The directions every generated prompt must address, per the plan. Shared so
    # each provider frames the model with the same required coverage.
    REQUIRED_DIRECTIONS = %w[
      camera_direction visual_direction character_movement dialogue audio_style
    ].freeze
  end
end
