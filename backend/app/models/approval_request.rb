require "digest"

# A secure, single-use, expiring request for the project owner to approve or
# reject a generated character over email. The raw link token is returned once
# at creation time and persisted only as a SHA-256 digest (mirrors RefreshToken).
#
# Lifecycle: pending -> approved | rejected | expired | cancelled. Only `pending`
# (and not yet past `expires_at`) is actionable; every other state is terminal.
# A superseded pending request (e.g. after regeneration) is `cancelled`.
class ApprovalRequest < ApplicationRecord
  belongs_to :project
  belongs_to :character
  belongs_to :user

  enum :status, {
    pending: 0,
    approved: 1,
    rejected: 2,
    expired: 3,
    cancelled: 4
  }, default: :pending

  validates :recipient_email, presence: true
  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { pending.where(expires_at: Time.current..) }

  # SHA-256 digest of a raw token — the only form ever stored.
  def self.digest(raw)
    Digest::SHA256.hexdigest(raw)
  end

  # Mints a raw single-use token and returns the digest for persistence. The raw
  # value is deliberately not stored anywhere; the caller emails it and discards.
  def self.generate_token
    raw = SecureRandom.urlsafe_base64(48)
    [ raw, digest(raw) ]
  end

  # True once the expiry has passed while still pending. `expired` status is set
  # lazily on access (see Approvals::ResolveToken) and proactively by the sweep
  # job, so a stored `pending` row can still be effectively expired.
  def past_expiry?
    expires_at.present? && expires_at.past?
  end

  # The request can still be acted upon: pending and within its expiry window.
  def actionable?
    pending? && !past_expiry?
  end
end
