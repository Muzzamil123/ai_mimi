# Processes a verified email-provider delivery webhook (signature checked at the
# controller). Correlates by provider_message_id and updates the tracking record's
# status. Expected payload: { "message_id", "event" (delivered|bounced|failed) }.
class HandleEmailDeliveryWebhookJob < ApplicationJob
  queue_as :mailers

  EVENT_STATUS = {
    "delivered" => :delivered,
    "bounce" => :bounced,
    "bounced" => :bounced,
    "dropped" => :failed,
    "failed" => :failed,
    "complaint" => :bounced
  }.freeze

  def perform(payload)
    payload = payload.with_indifferent_access
    message_id = payload[:message_id].presence || payload[:provider_message_id].presence
    return if message_id.blank?

    status = EVENT_STATUS[payload[:event].to_s]
    return if status.nil?

    delivery = EmailDelivery.where(provider_message_id: message_id).order(:created_at).last
    return if delivery.nil?

    attrs = { status: status }
    attrs[:delivered_at] = Time.current if status == :delivered
    attrs[:error_message] = payload[:reason].to_s.truncate(1000) if payload[:reason].present?
    delivery.update!(attrs)
  end
end
