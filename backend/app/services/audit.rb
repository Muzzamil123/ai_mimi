# Namespace for the append-only audit trail. Audit::Record is the single writer
# of AuditLog rows, used app-wide via the Auditable controller concern — for
# admin operations (Phase 11) and sensitive user actions (Phase 13).
module Audit
end
