module Health
  # Probes the connectivity of the platform's core infrastructure dependencies
  # and returns a {Health::Report}. Each probe fails closed (returns "error")
  # and never raises, so the health endpoint always responds.
  class CheckService < ApplicationService
    def call
      Report.new(
        version: Rails.application.config.x.app_version,
        components: {
          database: check_database,
          redis: check_redis,
          sidekiq: check_sidekiq
        },
      )
    end

    private

    def check_database
      ActiveRecord::Base.connection.execute("SELECT 1")
      Report::OK
    rescue StandardError => e
      log_failure(:database, e)
      Report::ERROR
    end

    def check_redis
      redis = Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"))
      redis.ping == "PONG" ? Report::OK : Report::ERROR
    rescue StandardError => e
      log_failure(:redis, e)
      Report::ERROR
    ensure
      redis&.close
    end

    def check_sidekiq
      result = Sidekiq.redis { |conn| conn.call("PING") }
      result == "PONG" ? Report::OK : Report::ERROR
    rescue StandardError => e
      log_failure(:sidekiq, e)
      Report::ERROR
    end

    def log_failure(component, error)
      Rails.logger.warn(
        message: "health_check_failed",
        component: component,
        error: error.class.name,
      )
    end
  end
end
