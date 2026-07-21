require "securerandom"
require "bcrypt"

# Asynchronously purges a deleted account's data and personal information
# (Phase 13, data-retention / right-to-erasure). Destroys the owner's projects
# (cascading to characters, videos, prompts, generations, and assets) and their
# tracked email deliveries, then anonymizes the surviving user row. The row is
# kept (anonymized) rather than destroyed so audit-trail references remain
# valid. Guarded to only run for an account already marked deleted, and
# idempotent (safe to retry).
class PurgeAccountJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    user = User.find_by(id: user_id)
    return if user.nil? || !user.status_deleted?

    user.projects.find_each(&:destroy!)
    user.email_deliveries.delete_all

    return if user.email.end_with?("@deleted.invalid") # already anonymized

    user.update_columns(
      name: "Deleted user",
      email: "deleted-#{user.id}@deleted.invalid",
      password_digest: BCrypt::Password.create(SecureRandom.hex(24)),
      notification_preferences: {},
      updated_at: Time.current
    )
  end
end
