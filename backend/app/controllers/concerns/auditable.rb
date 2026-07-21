# Records privileged/destructive and other sensitive actions to the audit
# trail. Included by the API base controller so any endpoint can capture who did
# what, to which resource, from where. Delegates to Audit::Record — the single
# writer of audit rows. Never pass secrets in metadata.
module Auditable
  extend ActiveSupport::Concern

  private

  def audit!(action, resource: nil, metadata: {})
    ::Audit::Record.call(
      actor: current_user,
      action: action,
      resource: resource,
      metadata: metadata,
      request_context: request_context
    )
  end
end
