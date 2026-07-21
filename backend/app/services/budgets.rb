# Namespace for budget evaluation and enforcement (Phase 12).
module Budgets
  # Raised when a hard (block) limit would be exceeded and the caller is not
  # permitted to override. `entries` describes the breached policies.
  class LimitExceeded < StandardError
    attr_reader :entries

    def initialize(message = "This action would exceed a budget limit", entries: [])
      super(message)
      @entries = entries
    end
  end

  # Outcome of an evaluation. `status` is "ok" | "warning" | "exceeded";
  # `blocked` is true when a hard limit would be exceeded; `entries` lists the
  # warning/exceeded policies (each a hash the API/UI can render).
  Result = Struct.new(:status, :blocked, :entries, keyword_init: true) do
    def blocked?
      blocked
    end
  end
end
