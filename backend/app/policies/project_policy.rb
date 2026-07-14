class ProjectPolicy < ApplicationPolicy
  def index?
    user.present?
  end

  def show?
    owner? || user&.admin?
  end

  def create?
    user.present?
  end

  def update?
    owner? || user&.admin?
  end

  def destroy?
    owner? || user&.admin?
  end

  def archive?
    update?
  end

  def restore?
    update?
  end

  private

  def owner?
    user && record.user_id == user.id
  end

  class Scope < Scope
    def resolve
      user&.admin? ? scope.all : scope.where(user_id: user&.id)
    end
  end
end
