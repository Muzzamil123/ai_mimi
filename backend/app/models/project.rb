class Project < ApplicationRecord
  belongs_to :user
  belongs_to :active_character, class_name: "Character", optional: true
  # A project owns exactly one character (enforced by a unique index on
  # characters.project_id). `active_character` points at it once approved.
  has_one :character, dependent: :destroy
  has_many :status_changes,
           -> { order(created_at: :asc) },
           class_name: "ProjectStatusChange",
           dependent: :destroy
  has_many :approval_requests, dependent: :destroy
  # A ready project owns many videos (Phase 6).
  has_many :videos, dependent: :destroy
  # Video-generation outputs across the project's videos (Phase 8). Deletion is
  # handled by the videos cascade / DB foreign keys.
  has_many :video_generations, dependent: :destroy
  # Stored output files across the project (Phase 9), for the project-wide archive.
  has_many :video_assets, through: :video_generations

  SUPPORTED_LANGUAGES = %w[english urdu roman_urdu punjabi].freeze
  SUPPORTED_PLATFORMS = %w[instagram_reels tiktok youtube_shorts other].freeze

  enum :status, {
    draft: 0,
    initializing_character: 1,
    awaiting_character_approval: 2,
    character_rejected: 3,
    ready: 4,
    failed: 5,
    archived: 6
  }, default: :draft

  # Guard rails for the project lifecycle. Character-driven transitions
  # (draft -> initializing_character, etc.) are exercised from Phase 4 onward.
  ALLOWED_TRANSITIONS = {
    "draft" => %w[initializing_character archived],
    "initializing_character" => %w[awaiting_character_approval failed archived],
    "awaiting_character_approval" => %w[ready character_rejected archived],
    "character_rejected" => %w[initializing_character archived],
    "ready" => %w[archived],
    "failed" => %w[draft initializing_character archived],
    "archived" => %w[draft initializing_character awaiting_character_approval character_rejected ready failed]
  }.freeze

  before_validation :assign_slug, on: :create

  validates :name, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, uniqueness: { scope: :user_id }
  validates :default_language, inclusion: { in: SUPPORTED_LANGUAGES }
  validates :default_tone, presence: true, length: { maximum: 100 }
  validate :target_platforms_supported
  validate :owner_unchanged, on: :update

  scope :not_archived, -> { where.not(status: statuses[:archived]) }
  scope :search, lambda { |query|
    next all if query.blank?

    where("name ILIKE ?", "%#{sanitize_sql_like(query)}%")
  }

  # Videos may only be generated once the project's character is approved.
  def generatable?
    ready?
  end

  # Transitions status, enforcing ALLOWED_TRANSITIONS, and records history.
  def transition_to!(new_status, actor: nil, reason: nil)
    target = new_status.to_s

    unless ALLOWED_TRANSITIONS.fetch(status, []).include?(target)
      raise Projects::InvalidTransition, "Cannot transition project from '#{status}' to '#{target}'"
    end

    transaction do
      previous = status
      update!(status: target, archived_at: (target == "archived" ? Time.current : nil))
      status_changes.create!(from_status: previous, to_status: target, actor: actor, reason: reason)
    end
  end

  private

  def assign_slug
    return if slug.present? || name.blank?

    base = name.parameterize.presence || "project"
    candidate = base
    suffix = 2
    while user_id && Project.where(user_id: user_id, slug: candidate).exists?
      candidate = "#{base}-#{suffix}"
      suffix += 1
    end
    self.slug = candidate
  end

  def owner_unchanged
    errors.add(:user_id, "cannot be changed") if user_id_changed?
  end

  def target_platforms_supported
    unsupported = Array(target_platforms) - SUPPORTED_PLATFORMS
    return if unsupported.empty?

    errors.add(:target_platforms, "contains unsupported values: #{unsupported.join(', ')}")
  end
end
