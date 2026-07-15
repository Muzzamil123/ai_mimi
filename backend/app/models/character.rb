class Character < ApplicationRecord
  belongs_to :project
  has_many :images,
           -> { order(created_at: :asc) },
           class_name: "CharacterImage",
           dependent: :destroy

  enum :status, {
    pending: 0,
    generating: 1,
    awaiting_approval: 2,
    rejected: 3,
    approved: 4,
    failed: 5
  }, default: :pending

  # Character lifecycle guard rails. `approved` is terminal for normal users;
  # only an audited admin reset (see #reset_by_admin!) may leave it.
  ALLOWED_TRANSITIONS = {
    "pending" => %w[generating failed],
    "generating" => %w[awaiting_approval failed],
    "awaiting_approval" => %w[approved rejected],
    "rejected" => %w[generating failed],
    "approved" => %w[],
    "failed" => %w[generating]
  }.freeze

  # The project status that must mirror each character status so that
  # "project status follows character status" holds. `pending` maps to nil
  # because a project stays in `draft` until generation actually starts.
  PROJECT_STATUS_FOR = {
    "generating" => "initializing_character",
    "awaiting_approval" => "awaiting_character_approval",
    "rejected" => "character_rejected",
    "approved" => "ready",
    "failed" => "failed"
  }.freeze

  validates :name, presence: true, length: { maximum: 255 }
  validates :provider, length: { maximum: 100 }, allow_nil: true
  validate :single_character_per_project, on: :create

  # The most recent generated image (the one shown for preview/approval).
  def latest_image
    images.last
  end

  def locked?
    approved?
  end

  # Transitions status while enforcing ALLOWED_TRANSITIONS, applying the
  # status-specific side effects (timestamps, project.active_character), keeping
  # the owning project's status in sync, and recording project history — all in
  # one transaction. Raises Characters::InvalidTransition on a disallowed move.
  def transition_to!(new_status, actor: nil, reason: nil)
    target = new_status.to_s

    unless ALLOWED_TRANSITIONS.fetch(status, []).include?(target)
      raise Characters::InvalidTransition, "Cannot transition character from '#{status}' to '#{target}'"
    end

    transaction do
      apply_status_side_effects(target)
      update!(status: target)
      sync_project_status!(target, actor: actor, reason: reason)
    end
  end

  # Audited administrative reset back to `pending` from any status, including an
  # approved (locked) character. Clears generation artifacts so the project can
  # start over. The caller is responsible for recording the audit trail.
  def reset_by_admin!(actor:, reason: "reset by administrator")
    transaction do
      project.update!(active_character_id: nil) if project.active_character_id == id
      images.destroy_all
      update!(
        status: :pending,
        approved_at: nil,
        rejected_at: nil,
        locked_at: nil,
        failure_reason: nil,
        rejection_feedback: nil,
        provider_job_id: nil,
        generation_id: nil
      )
      # Return the project to draft so a fresh generation can begin. This is an
      # admin override: it bypasses the normal transition guards (the locked
      # `ready` state has no ordinary path back) but still records history.
      reset_project_to_draft!(actor: actor, reason: reason)
    end
  end

  private

  def reset_project_to_draft!(actor:, reason:)
    return if project.status == "draft"

    previous = project.status
    project.update!(status: "draft", archived_at: nil)
    project.status_changes.create!(from_status: previous, to_status: "draft", actor: actor, reason: reason)
  end

  def apply_status_side_effects(target)
    case target
    when "generating"
      self.failure_reason = nil
      self.approved_at = nil
      self.rejected_at = nil
      self.locked_at = nil
    when "awaiting_approval"
      self.approved_at = nil
    when "approved"
      self.approved_at = Time.current
      self.locked_at = Time.current
      self.rejected_at = nil
    when "rejected"
      self.rejected_at = Time.current
    end
  end

  def sync_project_status!(target, actor:, reason:)
    if target == "approved"
      project.update!(active_character_id: id)
    end

    project_target = PROJECT_STATUS_FOR[target]
    return if project_target.nil? || project.status == project_target

    project.transition_to!(project_target, actor: actor, reason: reason || "character #{target}")
  end

  # Defence in depth alongside the unique index on project_id.
  def single_character_per_project
    return if project_id.blank?
    return unless Character.where(project_id: project_id).where.not(id: id).exists?

    errors.add(:project_id, "already has a character")
  end
end
