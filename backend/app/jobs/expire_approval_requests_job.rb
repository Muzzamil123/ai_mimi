# Proactively expires approval links whose window has passed and notifies the
# project owner that they need to request a fresh one. Intended to run on a
# schedule (see docs); safe to run at any cadence.
#
# Idempotent: only pending, past-expiry requests are touched, and each is flipped
# to `expired` before its email is queued, so re-runs never re-notify.
class ExpireApprovalRequestsJob < ApplicationJob
  queue_as :mailers

  def perform
    ApprovalRequest.pending.where(expires_at: ..Time.current).find_each do |request|
      request.update!(status: :expired)
      UserMailer.approval_link_expired(request).deliver_later
      Notifications::RecordDelivery.call(
        user: request.user, email_type: "approval_link_expired",
        project: request.project, dedupe_key: "approval_link_expired:#{request.id}"
      )
    end
  end
end
