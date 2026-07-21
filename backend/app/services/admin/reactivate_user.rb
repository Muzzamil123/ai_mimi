module Admin
  # Restores a suspended user to active. Only a suspended account can be
  # reactivated — a deleted account is terminal and is not reversible here.
  class ReactivateUser < ApplicationService
    def initialize(user, actor:)
      @user = user
      @actor = actor
    end

    def call
      unless @user.status_suspended?
        raise Admin::InvalidOperation, "Only a suspended account can be reactivated"
      end

      @user.update!(status: :active)
      @user
    end
  end
end
