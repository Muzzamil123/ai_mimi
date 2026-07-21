# Namespace for admin-portal operational service objects and their errors
# (Phase 11). Admin actions mutate platform state on behalf of an administrator;
# each is recorded in the audit trail from the controller layer (which holds the
# request context) via the Auditable concern / Audit::Record.
module Admin
  # Raised when an admin operation is attempted in an incompatible state
  # (e.g. reactivating a user who is not suspended, or an unknown setting key).
  class InvalidOperation < StandardError; end
end
