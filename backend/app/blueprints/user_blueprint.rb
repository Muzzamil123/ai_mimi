# Serializes a User for API responses. Never exposes password_digest or tokens.
class UserBlueprint < Blueprinter::Base
  identifier :id

  fields :name, :email, :role, :status

  field :email_verified do |user|
    user.email_verified?
  end

  field :created_at do |user|
    user.created_at.iso8601
  end
end
