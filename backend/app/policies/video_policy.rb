# Authorization for a project's videos. Access mirrors the owning project: the
# owner or an admin may list, view, and manage the project's videos.
class VideoPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    owner_or_admin?
  end

  def create?
    owner_or_admin?
  end

  def update?
    owner_or_admin?
  end

  def destroy?
    owner_or_admin?
  end

  def upload_audio?
    owner_or_admin?
  end

  private

  def owner_or_admin?
    return false unless user
    return true if user.admin?

    record.project.user_id == user.id
  end

  # Scopes videos to those whose project the user owns (admins see all). Used by
  # the index action so a non-owner never learns another user's video exists.
  class Scope < Scope
    def resolve
      return scope.all if user&.admin?

      scope.joins(:project).where(projects: { user_id: user&.id })
    end
  end
end
