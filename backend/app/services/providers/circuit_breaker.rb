module Providers
  # A minimal, shared circuit breaker for provider calls (Phase 13). After
  # `threshold` consecutive failures it opens for `cooldown` seconds, failing
  # fast (raising CircuitOpenError) instead of hammering a provider that is
  # down — protecting worker throughput and the provider's rate limits. State
  # lives in a cache store (shared Redis in real environments) so all processes
  # trip together; a successful call resets the counter.
  #
  # Only failures the breaker is told to count trip it (transient/connectivity),
  # not domain errors. Callers pass the list via `count_as_failure`.
  class CircuitBreaker
    DEFAULT_THRESHOLD = 5
    DEFAULT_COOLDOWN = 30

    def initialize(key:, store: nil, threshold: nil, cooldown: nil)
      @key = "circuit_breaker:#{key}"
      @store = store || default_store
      @threshold = (threshold || ENV.fetch("PROVIDER_CIRCUIT_THRESHOLD", DEFAULT_THRESHOLD)).to_i
      @cooldown = (cooldown || ENV.fetch("PROVIDER_CIRCUIT_COOLDOWN_SECONDS", DEFAULT_COOLDOWN)).to_i
      @provider = key
    end

    # Runs the block unless the circuit is open. `count_as_failure` lists the
    # error classes that should trip the breaker; those re-raise after being
    # counted. Any other error propagates without affecting breaker state.
    def run(count_as_failure: [ StandardError ])
      raise CircuitOpenError, @provider if open?

      result = yield
      reset!
      result
    rescue *Array(count_as_failure) => e
      record_failure!
      raise e
    end

    def open?
      failure_count >= @threshold
    end

    private

    def failure_count
      @store.read(@key).to_i
    end

    def record_failure!
      current = failure_count + 1
      # Re-set with the cooldown TTL so the open state auto-heals (half-open:
      # the next call after expiry runs and either resets or re-opens).
      @store.write(@key, current, expires_in: @cooldown)
    end

    def reset!
      @store.delete(@key)
    end

    # A dedicated store so the breaker works regardless of Rails.cache config:
    # shared Redis in real environments (all processes trip together), a null
    # store in tests so it never trips and specs stay hermetic.
    def default_store
      self.class.shared_store
    end

    def self.shared_store
      @shared_store ||=
        if Rails.env.test?
          ActiveSupport::Cache::NullStore.new
        else
          ActiveSupport::Cache::RedisCacheStore.new(
            url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
            namespace: "circuit_breaker"
          )
        end
    end
  end
end
