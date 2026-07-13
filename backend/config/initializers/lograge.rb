# Structured, single-line JSON request logging. Disabled in the test
# environment to keep spec output readable.
Rails.application.configure do
  config.lograge.enabled = !Rails.env.test?
  config.lograge.formatter = Lograge::Formatters::Json.new

  config.lograge.custom_payload do |controller|
    { request_id: controller.request.request_id }
  end

  config.lograge.custom_options = lambda do |event|
    {
      time: event.time.iso8601,
      params: event.payload[:params]&.except("controller", "action", "format"),
    }
  end
end
