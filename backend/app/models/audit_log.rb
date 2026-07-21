# Append-only record of a privileged/destructive action performed through the
# admin portal (Phase 11). Created via Admin::RecordAudit / the Auditable
# controller concern. Rows are immutable: they are never updated or destroyed by
# the application. The actor is a polymorphic association (a User admin today)
# and is intentionally not a hard FK so the trail outlives the actor.
class AuditLog < ApplicationRecord
  # created_at is set explicitly; there is no updated_at column.
  self.record_timestamps = false

  belongs_to :actor, polymorphic: true, optional: true

  validates :action, presence: true

  before_validation :stamp_created_at, on: :create

  scope :recent, -> { order(created_at: :desc) }
  scope :for_action, ->(action) { where(action: action) if action.present? }
  scope :for_actor, ->(actor) { where(actor: actor) if actor.present? }
  scope :for_resource, lambda { |type, id|
    next all if type.blank?

    rel = where(resource_type: type)
    id.present? ? rel.where(resource_id: id) : rel
  }

  # Guards against accidental mutation of an audit trail.
  def readonly?
    persisted?
  end

  private

  def stamp_created_at
    self.created_at ||= Time.current
  end
end
