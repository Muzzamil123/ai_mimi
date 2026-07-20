class Video < ApplicationRecord
  belongs_to :project
  has_many :status_changes,
           -> { order(created_at: :asc) },
           class_name: "VideoStatusChange",
           dependent: :destroy
  # A video owns many prompt versions (Phase 7); `active_prompt` points at the
  # approved one that automated video generation (Phase 8) will use.
  has_many :prompts, dependent: :destroy
  belongs_to :active_prompt, class_name: "Prompt", optional: true

  # Phase 1 supports 15-second videos only. Longer durations (1–5 minutes) are a
  # future capability; the architecture supports them behind a flag so enabling
  # them later does not require a schema or model rewrite.
  DEFAULT_DURATION_SECONDS = 15
  LONG_FORM_MIN_SECONDS = 60
  LONG_FORM_MAX_SECONDS = 300

  enum :status, {
    draft: 0,
    transcribing: 1,
    idea_ready: 2,
    generating_prompt: 3,
    prompt_ready: 4,
    queued: 5,
    generating: 6,
    partially_completed: 7,
    completed: 8,
    failed: 9,
    cancelled: 10
  }, default: :draft

  # Guard rails for the video lifecycle. Phase 6 only exercises the idea/
  # transcription portion (draft, transcribing, idea_ready, failed, cancelled);
  # the prompt/generation states are reserved for Phases 7–8 and wired here so
  # those phases only need to call #transition_to! without touching the machine.
  ALLOWED_TRANSITIONS = {
    "draft" => %w[transcribing idea_ready generating_prompt cancelled],
    "transcribing" => %w[idea_ready failed cancelled],
    "idea_ready" => %w[transcribing generating_prompt draft cancelled],
    "generating_prompt" => %w[prompt_ready failed cancelled],
    "prompt_ready" => %w[generating_prompt queued cancelled],
    "queued" => %w[generating cancelled],
    "generating" => %w[partially_completed completed failed cancelled],
    "partially_completed" => %w[generating completed failed cancelled],
    "completed" => %w[],
    "failed" => %w[transcribing idea_ready generating_prompt draft cancelled],
    "cancelled" => %w[]
  }.freeze

  before_validation :apply_project_defaults, on: :create

  validates :title, presence: true, length: { maximum: 255 }
  validates :language, inclusion: { in: Project::SUPPORTED_LANGUAGES }
  validates :tone, length: { maximum: 100 }, allow_nil: true
  validate :duration_supported

  scope :search, lambda { |query|
    next all if query.blank?

    where("title ILIKE :q OR idea_text ILIKE :q", q: "%#{sanitize_sql_like(query)}%")
  }

  # True once the video has a usable idea (typed or transcribed). The idea is the
  # input Phase 7 turns into a prompt.
  def idea_present?
    idea_text.present? || transcript.present?
  end

  def audio_attached?
    idea_audio_storage_key.present?
  end

  # The latest live prompt version (the one the workspace acts on): a generation
  # in flight, or the most recent draft/approved version. nil until first asked.
  def current_prompt
    prompts.live.by_version.first
  end

  # The idea text used as the source for prompt generation: the (editable)
  # transcript when present, else the typed idea.
  def idea_source
    transcript.presence || idea_text
  end

  # Whether long-form (1–5 minute) durations are enabled. Off by default so
  # Phase 1 enforces 15 seconds; a future phase flips the flag.
  def self.long_form_enabled?
    ActiveModel::Type::Boolean.new.cast(ENV["VIDEO_LONG_FORM_ENABLED"])
  end

  # Transitions status, enforcing ALLOWED_TRANSITIONS, and records history.
  # Videos do not drive the project's status (a ready project simply owns many
  # videos), so unlike Character this does not sync the parent.
  def transition_to!(new_status, actor: nil, reason: nil)
    target = new_status.to_s

    unless ALLOWED_TRANSITIONS.fetch(status, []).include?(target)
      raise Videos::InvalidTransition, "Cannot transition video from '#{status}' to '#{target}'"
    end

    transaction do
      previous = status
      update!(status: target)
      status_changes.create!(from_status: previous, to_status: target, actor: actor, reason: reason)
    end
  end

  private

  # Videos inherit the project's language/tone defaults unless overridden, and
  # default to the Phase 1 duration.
  def apply_project_defaults
    self.language ||= project&.default_language
    self.tone ||= project&.default_tone
    # Default to a value that is valid under the active duration policy so an
    # unspecified duration never fails validation (15s now; the long-form minimum
    # when that mode is enabled).
    self.duration_seconds ||=
      self.class.long_form_enabled? ? LONG_FORM_MIN_SECONDS : DEFAULT_DURATION_SECONDS
  end

  def duration_supported
    if self.class.long_form_enabled?
      unless duration_seconds&.between?(LONG_FORM_MIN_SECONDS, LONG_FORM_MAX_SECONDS)
        errors.add(:duration_seconds, "must be between #{LONG_FORM_MIN_SECONDS} and #{LONG_FORM_MAX_SECONDS} seconds")
      end
    elsif duration_seconds != DEFAULT_DURATION_SECONDS
      errors.add(:duration_seconds, "must be #{DEFAULT_DURATION_SECONDS} seconds")
    end
  end
end
