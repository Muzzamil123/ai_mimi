require "net/http"

module Providers
  # Mixed into the real HTTP provider adapters to wrap their network call in a
  # shared circuit breaker (Phase 13). Only connectivity/timeout failures count
  # toward tripping the breaker; a domain/HTTP-status error does not. When the
  # circuit is open, Providers::CircuitOpenError is raised — each adapter maps it
  # to its own retryable provider error so jobs back off and retry later.
  module Breakable
    NETWORK_ERRORS = [ Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, SocketError ].freeze

    private

    def with_circuit(name, &block)
      Providers::CircuitBreaker.new(key: name).run(count_as_failure: NETWORK_ERRORS, &block)
    end
  end
end
