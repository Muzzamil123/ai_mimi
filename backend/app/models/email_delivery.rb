# Tracking record for every workflow email/notification sent to a project owner.
# Powers the in-app notification center, delivery-status tracking (via the
# provider webhook), duplicate prevention, and retries.
class EmailDelivery < ApplicationRecord
  belongs_to :user
  belongs_to :project, optional: true
  belongs_to :video, optional: true

  # All tracked workflow email types.
  EMAIL_TYPES = %w[
    character_ready character_approved character_rejected approval_link_expired
    prompt_ready video_generation_started video_generation_partially_completed
    video_generation_completed video_generation_failed
  ].freeze

  # Types a user may disable in preferences; everything else is mandatory
  # (approval-critical or completion/failure results).
  OPTIONAL_TYPES = %w[
    prompt_ready video_generation_started video_generation_partially_completed
  ].freeze

  enum :status, {
    queued: 0,
    sent: 1,
    delivered: 2,
    failed: 3,
    bounced: 4
  }, default: :queued

  validates :email_type, presence: true
  validates :recipient, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :unread, -> { where(read_at: nil) }

  def read?
    read_at.present?
  end
end
