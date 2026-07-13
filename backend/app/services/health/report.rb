module Health
  # Immutable value object describing the outcome of a system health check.
  class Report
    OK = "ok"
    ERROR = "error"

    attr_reader :version, :components, :checked_at

    # @param version [String] application version
    # @param components [Hash{Symbol=>String}] component => "ok"/"error"
    # @param checked_at [Time]
    def initialize(version:, components:, checked_at: Time.current)
      @version = version
      @components = components
      @checked_at = checked_at
    end

    def status
      healthy? ? OK : "degraded"
    end

    def healthy?
      components.values.all? { |value| value == OK }
    end
  end
end
