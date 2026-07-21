module Admin
  # Suspends a user account. A suspended user can no longer authenticate: the
  # stateless access-token check already rejects a non-active account, and here
  # we also revoke every outstanding refresh token so no new access token can be
  # minted. Idempotent-friendly: re-suspending an already-suspended user is a
  # no-op. Auditing is performed by the caller (controller) with request context.
  class SuspendUser < ApplicationService
    def initialize(user, actor:)
      @user = user
      @actor = actor
    end

    def call
      if @user.status_deleted?
        raise Admin::InvalidOperation, "A deleted account cannot be suspended"
      end
      if @user == @actor
        raise Admin::InvalidOperation, "You cannot suspend your own account"
      end

      @user.transaction do
        @user.update!(status: :suspended) unless @user.status_suspended?
        @user.refresh_tokens.active.find_each(&:revoke!)
      end
      @user
    end
  end
end
