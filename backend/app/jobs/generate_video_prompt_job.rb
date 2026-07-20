# Generates the first prompt version for a video. Behaviour lives in the shared
# Prompts::GenerationJob base; this is a distinct, observable entry point for
# initial generation.
class GenerateVideoPromptJob < Prompts::GenerationJob
end
