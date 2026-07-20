# Generates a subsequent prompt version for a video (regeneration). Behaviour
# lives in the shared Prompts::GenerationJob base; this is a distinct, observable
# entry point for repeat generation.
class RegenerateVideoPromptJob < Prompts::GenerationJob
end
