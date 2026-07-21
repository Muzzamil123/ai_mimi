# Base for workflow-email jobs. Runs on the mailers queue and retries transient
# delivery failures with backoff (DeliverEmail re-raises on failure, and marks
# the tracking record failed so it stays retryable even after exhaustion).
class NotificationEmailJob < ApplicationJob
  queue_as :mailers

  retry_on StandardError, wait: :polynomially_longer, attempts: 5
end
