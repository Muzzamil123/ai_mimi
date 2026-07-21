# Namespace for cross-provider infrastructure shared by the AI adapters
# (Phase 13): credential resolution and the circuit breaker. Keeps secret access
# and failure-isolation policy in one place rather than duplicated per adapter.
module Providers
  # Raised when a provider is skipped because its circuit breaker is open.
  class CircuitOpenError < StandardError
    def initialize(provider)
      super("Provider '#{provider}' is temporarily unavailable (circuit open)")
    end
  end
end
