# The notification-center view of a tracked email. Recipient is intentionally
# omitted (it's always the owner's own account email).
class EmailDeliveryBlueprint < Blueprinter::Base
  identifier :id

  fields :email_type, :subject, :status, :project_id, :video_id

  field :read do |delivery|
    delivery.read?
  end

  field :created_at do |delivery|
    delivery.created_at.iso8601
  end
end
