class User < ApplicationRecord
  has_secure_password

  has_many :refresh_tokens, dependent: :destroy
  has_many :projects, dependent: :destroy

  enum :role, { user: 0, admin: 1 }, default: :user
  enum :status, { active: 0, suspended: 1, deleted: 2 }, default: :active, prefix: :status

  # bcrypt silently truncates beyond 72 bytes, so cap the max explicitly.
  PASSWORD_LENGTH = (8..72)

  before_validation :normalize_email

  validates :name, presence: true, length: { maximum: 255 }
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP },
            length: { maximum: 255 }
  validates :password, length: { in: PASSWORD_LENGTH }, allow_nil: true

  # Purpose-bound, expiring, stateless tokens (Rails 7.1). The email-verification
  # token invalidates once verified; the password-reset token invalidates as soon
  # as the password changes (password_salt changes).
  generates_token_for :email_verification, expires_in: 24.hours do
    email_verified_at
  end

  generates_token_for :password_reset, expires_in: 2.hours do
    password_salt&.last(10)
  end

  def email_verified?
    email_verified_at.present?
  end

  def mark_email_verified!
    update!(email_verified_at: Time.current) unless email_verified?
  end

  def touch_last_login!
    update_column(:last_login_at, Time.current)
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end
end
