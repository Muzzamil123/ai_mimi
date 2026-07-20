require "digest"

# Namespace for Google Labs video-generation service objects, errors, and the
# variant matrix (Phase 8). Generation produces exactly four outputs per request:
# two aspect ratios × two variations, all 15 seconds, all using the project's
# approved character image and the video's approved prompt.
module VideoGenerations
  # Raised when a video-generation status transition is not permitted.
  class InvalidTransition < StandardError; end

  # Raised when generation is attempted in an incompatible state (e.g. no
  # approved prompt/character, or a batch is already running).
  class InvalidState < StandardError; end

  # Signals a transient provider failure that Sidekiq should retry. On exhaustion
  # the variant is marked failed (see VideoGenerations::GenerationJob).
  class TransientError < StandardError; end

  ASPECT_RATIOS = %w[3:4 9:16].freeze
  VARIATIONS = [ 1, 2 ].freeze

  # The four required outputs per generation request, in a stable order.
  def self.variant_matrix
    ASPECT_RATIOS.flat_map { |ratio| VARIATIONS.map { |variation| { aspect_ratio: ratio, variation_number: variation } } }
  end

  # Deterministic idempotency key: identical (video, prompt, character, aspect,
  # variation) always maps to the same key, so a repeated request find-or-creates
  # the same row instead of duplicating an active job.
  def self.idempotency_key(video_id:, prompt_id:, character_id:, aspect_ratio:, variation_number:)
    Digest::SHA256.hexdigest("#{video_id}:#{prompt_id}:#{character_id}:#{aspect_ratio}:#{variation_number}")
  end
end
