# A single generated (or manually edited) version of a video's prompt. Versions
# accumulate per video — the version history — and exactly one may be `approved`
# and pointed to by video.active_prompt_id. Immutable once superseded/failed.
class Prompt < ApplicationRecord
  belongs_to :video
  # Who authored this version: the requesting user for an AI generation or a
  # manual edit. Polymorphic so a future automated actor can be attributed too.
  belongs_to :created_by, polymorphic: true, optional: true

  enum :status, {
    generating: 0,
    draft: 1,
    approved: 2,
    failed: 3,
    superseded: 4
  }, default: :generating

  # Prompt lifecycle guard rails. A version is generated (or created as a manual
  # draft), may be approved, and is superseded when a newer/other version wins.
  ALLOWED_TRANSITIONS = {
    "generating" => %w[draft failed superseded],
    "draft" => %w[approved superseded],
    "approved" => %w[superseded],
    "failed" => %w[superseded],
    "superseded" => %w[]
  }.freeze

  validates :version, presence: true,
                      numericality: { only_integer: true, greater_than: 0 },
                      uniqueness: { scope: :video_id }
  # Content is required once a version carries usable text (draft/approved); an
  # in-flight `generating` row has none yet.
  validates :content, presence: true, if: -> { draft? || approved? }

  # Versions that still count as live (not superseded, not failed).
  scope :live, -> { where.not(status: %i[superseded failed]) }
  scope :by_version, -> { order(version: :desc) }

  def transition_to!(new_status)
    target = new_status.to_s

    unless ALLOWED_TRANSITIONS.fetch(status, []).include?(target)
      raise Prompts::InvalidTransition, "Cannot transition prompt from '#{status}' to '#{target}'"
    end

    update!(status: target)
  end
end
