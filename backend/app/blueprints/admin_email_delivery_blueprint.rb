# Full email-delivery log for the admin portal. Unlike the user-facing
# EmailDeliveryBlueprint, this includes the recipient, provider, and delivery
# diagnostics an operator needs to troubleshoot a failed send.
class AdminEmailDeliveryBlueprint < Blueprinter::Base
  identifier :id

  fields :user_id, :project_id, :video_id, :email_type, :recipient,
         :subject, :provider, :provider_message_id, :status, :error_message

  field :sent_at do |delivery|
    delivery.sent_at&.iso8601
  end

  field :delivered_at do |delivery|
    delivery.delivered_at&.iso8601
  end

  field :created_at do |delivery|
    delivery.created_at.iso8601
  end
end
