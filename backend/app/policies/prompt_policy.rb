# Authorization for a video's prompts. Access mirrors the owning project: the
# owner or an admin may view versions and drive generation/approval.
class PromptPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    owner_or_admin?
  end

  def create?
    owner_or_admin?
  end

  def generate?
    owner_or_admin?
  end

  def approve?
    owner_or_admin?
  end

  private

  def owner_or_admin?
    return false unless user
    return true if user.admin?

    record.video.project.user_id == user.id
  end

  # Scopes prompts to those on videos in the user's own projects (admins see
  # all), so a non-owner never learns another user's prompt exists.
  class Scope < Scope
    def resolve
      return scope.all if user&.admin?

      scope.joins(video: :project).where(projects: { user_id: user&.id })
    end
  end
end
