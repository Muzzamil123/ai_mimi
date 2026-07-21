# Re-attempts a failed workflow-email delivery (owner- or admin-triggered). Only
# retries failed, video-backed deliveries — re-running DeliverEmail on the same
# dedupe_key reuses the record and re-sends.
class RetryEmailDeliveryJob < NotificationEmailJob
  def perform(email_delivery_id)
    delivery = EmailDelivery.find_by(id: email_delivery_id)
    return if delivery.nil? || !delivery.failed? || delivery.video_id.nil?

    Notifications::DeliverEmail.call(
      email_type: delivery.email_type,
      video: delivery.video,
      dedupe_key: delivery.dedupe_key
    )
  end
end
