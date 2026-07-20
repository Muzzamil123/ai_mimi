# Authorization for a video's generation outputs. Access mirrors the owning
# project: the owner or an admin may view, start, retry, and cancel.
class VideoGenerationPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def create?
    owner_or_admin?
  end

  def retry?
    owner_or_admin?
  end

  def cancel?
    owner_or_admin?
  end

  private

  def owner_or_admin?
    return false unless user
    return true if user.admin?

    record.video.project.user_id == user.id
  end

  # Scopes generations to those on videos in the user's own projects (admins see
  # all), so a non-owner never learns another user's output exists.
  class Scope < Scope
    def resolve
      return scope.all if user&.admin?

      scope.joins(video: :project).where(projects: { user_id: user&.id })
    end
  end
end
