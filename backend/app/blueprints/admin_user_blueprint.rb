# Richer user view for the admin portal (account management). Never exposes
# password_digest or tokens.
class AdminUserBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :email, :role, :status

  field :email_verified do |user|
    user.email_verified?
  end

  field :projects_count do |user|
    # Uses the counter column selected by the controller list query when present
    # (comes back as a string), else falls back to a count for the show action.
    user.has_attribute?(:projects_count) ? user.projects_count.to_i : user.projects.count
  end

  field :last_login_at do |user|
    user.last_login_at&.iso8601
  end

  field :created_at do |user|
    user.created_at.iso8601
  end

  field :updated_at do |user|
    user.updated_at.iso8601
  end
end
