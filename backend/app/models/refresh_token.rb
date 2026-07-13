require "digest"

# Opaque refresh token, stored only as a SHA-256 digest. The raw value is
# returned to the client once at issue time and never persisted in the clear.
class RefreshToken < ApplicationRecord
  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(revoked_at: nil).where(expires_at: Time.current..) }

  def self.digest(raw)
    Digest::SHA256.hexdigest(raw)
  end

  def active?
    revoked_at.nil? && expires_at.future?
  end

  def revoke!
    return if revoked_at

    update!(revoked_at: Time.current)
  end
end
