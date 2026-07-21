# Sidekiq connects to Redis using REDIS_URL, shared with the Rails cache/client.
redis_config = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

Sidekiq.configure_server do |config|
  config.redis = redis_config

  # A job that exhausts its retries lands in the Dead set (retained by Sidekiq
  # for later inspection/retry from the dashboard). Report it through the shared
  # error tracker so exhaustion is observable, not silent (Phase 13).
  config.death_handlers << lambda do |job, exception|
    Rails.error.report(
      exception,
      handled: false,
      severity: :error,
      context: { sidekiq_job: job["class"], jid: job["jid"], queue: job["queue"] },
      source: "sidekiq.death_handler"
    )
  end
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end
