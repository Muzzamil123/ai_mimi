# One provider output (a single aspect-ratio + variation) for a video. Exactly
# four per generation request. Each is tracked independently so successes and
# failures are isolated (partial completion). The asset itself is downloaded and
# stored in Phase 9; this model tracks the provider job through to completion.
class VideoGeneration < ApplicationRecord
  belongs_to :video
  belongs_to :project
  belongs_to :character
  belongs_to :prompt

  enum :status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3,
    cancelled: 4
  }, default: :pending

  ALLOWED_TRANSITIONS = {
    "pending" => %w[processing failed cancelled],
    "processing" => %w[completed failed cancelled],
    "completed" => %w[],
    "failed" => %w[pending cancelled],
    "cancelled" => %w[]
  }.freeze

  validates :aspect_ratio, inclusion: { in: VideoGenerations::ASPECT_RATIOS }
  validates :variation_number, inclusion: { in: VideoGenerations::VARIATIONS }
  validates :duration_seconds, numericality: { equal_to: Video::DEFAULT_DURATION_SECONDS }
  validates :idempotency_key, presence: true, uniqueness: true
  validates :progress, numericality: { in: 0..100 }

  scope :active, -> { where(status: %i[pending processing]) }
  scope :terminal, -> { where(status: %i[completed failed cancelled]) }

  def terminal?
    completed? || failed? || cancelled?
  end

  # Human label, e.g. "3:4 #1", for progress cards and logs.
  def label
    "#{aspect_ratio} ##{variation_number}"
  end

  # Transitions status while enforcing ALLOWED_TRANSITIONS and applying the
  # status-specific timestamps, in one update. Raises on a disallowed move.
  def transition_to!(new_status, progress: nil, error_code: nil, error_message: nil)
    target = new_status.to_s

    unless ALLOWED_TRANSITIONS.fetch(status, []).include?(target)
      raise VideoGenerations::InvalidTransition, "Cannot transition video generation from '#{status}' to '#{target}'"
    end

    attrs = { status: target }
    attrs[:progress] = progress if progress
    # Clear both error fields symmetrically so a row never carries a stale
    # message with a nil code (e.g. on a retry back to pending).
    attrs[:error_code] = error_code
    attrs[:error_message] = error_message&.to_s&.truncate(1000)
    attrs[:started_at] = Time.current if target == "processing" && started_at.nil?
    if target == "completed"
      attrs[:completed_at] = Time.current
      attrs[:progress] = 100
    end

    update!(attrs)
  end
end
