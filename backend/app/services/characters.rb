# Namespace for character lifecycle service objects and their errors.
module Characters
  # Raised when a character status transition is not permitted by its state machine.
  class InvalidTransition < StandardError; end

  # Raised when an operation is attempted on a character in an incompatible state
  # (e.g. regenerating an approved character, approving before generation).
  class InvalidState < StandardError; end

  # Signals a transient generation failure that Sidekiq should retry. On
  # exhaustion the generation is marked failed (see Characters::GenerationJob).
  class TransientError < StandardError; end

  # Maps stored image MIME types to file extensions for storage keys/filenames.
  MIME_EXTENSIONS = {
    "image/png" => "png",
    "image/jpeg" => "jpg",
    "image/jpg" => "jpg",
    "image/webp" => "webp"
  }.freeze

  def self.extension_for(mime_type)
    MIME_EXTENSIONS.fetch(mime_type.to_s, "bin")
  end
end
