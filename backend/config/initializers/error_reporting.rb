# Centralised error tracking (Phase 13). Subscribes a structured-logging
# reporter to Rails' error-reporting API (`Rails.error.report`), so handled and
# unhandled errors are captured uniformly with context (and never secrets — the
# log formatter's parameter filtering still applies to anything logged).
#
# An external error tracker (e.g. Sentry) can be layered in without code changes
# here: add the `sentry-ruby`/`sentry-rails` gem and set SENTRY_DSN — its
# railtie registers its own Rails.error subscriber alongside this one.
class StructuredErrorSubscriber
  def report(error, handled:, severity:, context:, source: nil)
    Rails.logger.error(
      message: "error_reported",
      error_class: error.class.name,
      error_message: error.message,
      handled: handled,
      severity: severity,
      source: source,
      context: context.except(:exception, :backtrace)
    )
  end
end

Rails.error.subscribe(StructuredErrorSubscriber.new) if Rails.error.respond_to?(:subscribe)
