# Namespace for project lifecycle service objects and their errors.
module Projects
  # Raised when a status transition is not permitted by the state machine or a
  # lifecycle guard (e.g. editing/deleting a non-draft project).
  class InvalidTransition < StandardError; end
end
