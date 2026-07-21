require "bigdecimal"

module Pricing
  # Computes the cost of a billable call from the configured ProviderPrice for
  # the given provider/service (+ optional model). `units` is a hash of the
  # usage counts; only the rates present on the price row contribute. Returns a
  # Pricing::Result — `configured: false` when no price row matches, so callers
  # can fall back to a provider-reported figure.
  class Calculate < ApplicationService
    # units keys → the price column they multiply.
    UNIT_RATES = {
      input_tokens: :per_input_token,
      output_tokens: :per_output_token,
      generated_images: :per_image,
      generated_seconds: :per_second,
      requests: :per_request
    }.freeze

    def initialize(provider:, service_type:, model: nil, units: {})
      @provider = provider
      @service_type = service_type
      @model = model
      @units = (units || {}).symbolize_keys
    end

    def call
      price = ProviderPrice.lookup(provider: @provider, service_type: @service_type, model: @model)
      return Result.new(amount: nil, currency: "USD", configured: false) if price.nil?

      amount = UNIT_RATES.sum(BigDecimal("0")) do |unit_key, rate_col|
        rate = price.public_send(rate_col)
        quantity = @units[unit_key]
        next BigDecimal("0") if rate.nil? || quantity.nil?

        BigDecimal(rate.to_s) * BigDecimal(quantity.to_s)
      end

      Result.new(amount: amount, currency: price.currency, configured: true)
    end
  end
end
