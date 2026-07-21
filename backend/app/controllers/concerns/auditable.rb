# Records privileged/destructive actions to the audit trail. Included by the
# admin base controller so every mutating admin endpoint can capture who did
# what, to which resource, from where. Delegates to Admin::RecordAudit — the
# single writer of audit rows. Never pass secrets in metadata.
module Auditable
  extend ActiveSupport::Concern

  private

  def audit!(action, resource: nil, metadata: {})
    ::Admin::RecordAudit.call(
      actor: current_user,
      action: action,
      resource: resource,
      metadata: metadata,
      request_context: request_context
    )
  end
end
