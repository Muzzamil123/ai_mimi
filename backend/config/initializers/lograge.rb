# Structured, single-line JSON request logging. Disabled in the test
# environment to keep spec output readable.
Rails.application.configure do
  config.lograge.enabled = !Rails.env.test?
  config.lograge.formatter = Lograge::Formatters::Json.new

  config.lograge.custom_payload do |controller|
    { request_id: controller.request.request_id }
  end

  # IMPORTANT: lograge replaces Rails' default log subscriber, so it does NOT
  # apply `config.filter_parameters` automatically. We must filter params here
  # ourselves, otherwise passwords / tokens would be logged in cleartext.
  parameter_filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)

  config.lograge.custom_options = lambda do |event|
    params = event.payload[:params]&.except("controller", "action", "format")
    {
      time: event.time.iso8601,
      params: params && parameter_filter.filter(params)
    }
  end
end
