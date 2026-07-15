# Authorization for a project's character. Access mirrors the owning project:
# the owner or an admin may view and drive the lifecycle. Only an admin may
# reset an (approved, locked) character.
class CharacterPolicy < ApplicationPolicy
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

  def generate?
    owner_or_admin?
  end

  def approve?
    owner_or_admin?
  end

  def reject?
    owner_or_admin?
  end

  def image?
    owner_or_admin?
  end

  # Reset is the only path out of the locked `approved` state — admins only.
  def reset?
    user&.admin?
  end

  private

  def owner_or_admin?
    return false unless user
    return true if user.admin?

    record.project.user_id == user.id
  end
end
