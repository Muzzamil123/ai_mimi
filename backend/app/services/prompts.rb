# Namespace for prompt-generation service objects and their errors (Phase 7:
# OpenAI video-prompt generation and versioning).
module Prompts
  # Raised when a prompt status transition is not permitted by its state machine.
  class InvalidTransition < StandardError; end

  # Raised when an operation is attempted in an incompatible state (e.g.
  # generating a prompt for a video with no idea, approving a non-draft prompt).
  class InvalidState < StandardError; end

  # Signals a transient generation failure that Sidekiq should retry. On
  # exhaustion the prompt is marked failed (see Prompts::GenerationJob).
  class TransientError < StandardError; end
end
