require "bigdecimal"

module Usage
  # Records one billable provider call to the ProviderUsage ledger, idempotently
  # (keyed by the polymorphic source, so a job retry updates the same row rather
  # than duplicating it). Cost comes from configurable pricing when available,
  # otherwise falls back to the provider-reported figure, otherwise 0 — and the
  # chosen source is tagged in metadata (`configured` / `provider_fallback` /
  # `unpriced`) so admins can spot pricing gaps. Never raises on a pricing gap.
  class Record < ApplicationService
    def initialize(source:, provider:, service_type:, model: nil,
                   user: nil, project: nil, video: nil, provider_request_id: nil,
                   input_tokens: nil, output_tokens: nil, generated_images: nil,
                   generated_seconds: nil, units: nil, provider_reported_cost: nil,
                   occurred_at: nil, metadata: {})
      @source = source
      @provider = provider.to_s
      @service_type = service_type.to_s
      @model = model
      @user = user
      @project = project
      @video = video
      @provider_request_id = provider_request_id
      @unit_counts = {
        input_tokens: input_tokens, output_tokens: output_tokens,
        generated_images: generated_images, generated_seconds: generated_seconds,
        requests: units
      }
      @provider_reported_cost = provider_reported_cost
      @occurred_at = occurred_at
      @metadata = (metadata || {}).stringify_keys
    end

    def call
      # A provider-less call can't be attributed or billed; skip rather than
      # break the domain operation that invoked us (recording is best-effort).
      if @provider.blank?
        Rails.logger.warn(message: "usage_record_skipped_no_provider", service_type: @service_type,
                                     source_type: @source&.class&.name, source_id: @source&.id)
        return nil
      end

      cost, currency, pricing_source = resolve_cost

      usage = if @source
        ProviderUsage.find_or_initialize_by(source_type: @source.class.name, source_id: @source.id)
      else
        ProviderUsage.new
      end

      usage.assign_attributes(
        user: @user, project: @project, video: @video,
        provider: @provider, service_type: @service_type, model: @model.presence,
        provider_request_id: @provider_request_id,
        input_tokens: @unit_counts[:input_tokens],
        output_tokens: @unit_counts[:output_tokens],
        generated_images: @unit_counts[:generated_images],
        generated_seconds: @unit_counts[:generated_seconds],
        units: @unit_counts[:requests],
        estimated_cost: cost, currency: currency,
        occurred_at: @occurred_at || usage.occurred_at || Time.current,
        metadata: @metadata.merge("pricing_source" => pricing_source)
      )
      usage.save!
      usage
    end

    private

    def resolve_cost
      priced = Pricing::Calculate.call(
        provider: @provider, service_type: @service_type, model: @model, units: @unit_counts
      )
      return [ priced.amount, priced.currency, "configured" ] if priced.configured?

      if @provider_reported_cost.present?
        return [ BigDecimal(@provider_reported_cost.to_s), "USD", "provider_fallback" ]
      end

      [ BigDecimal("0"), "USD", "unpriced" ]
    end
  end
end
