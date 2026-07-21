module Accounts
  # Handles an account-deletion request (Phase 13). Immediately revokes every
  # session and marks the account deleted (so access stops at once — the
  # stateless access-token check already rejects a non-active account), then
  # enqueues the asynchronous purge of the owner's data and PII. Idempotent:
  # re-requesting on an already-deleted account just re-enqueues the purge.
  class RequestDeletion < ApplicationService
    def initialize(user)
      @user = user
    end

    def call
      @user.transaction do
        @user.refresh_tokens.active.find_each(&:revoke!)
        @user.update!(status: :deleted) unless @user.status_deleted?
      end
      PurgeAccountJob.perform_later(@user.id)
      @user
    end
  end
end
