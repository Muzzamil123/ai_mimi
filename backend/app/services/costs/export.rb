require "csv"

module Costs
  # Builds a CSV export of the usage ledger over a window, optionally filtered by
  # provider — the admin "usage export". Streams rows in batches to keep memory
  # flat on large ledgers.
  class Export < ApplicationService
    HEADERS = %w[
      id occurred_at provider service_type model user_id project_id video_id
      input_tokens output_tokens generated_images generated_seconds
      estimated_cost currency pricing_source provider_request_id
    ].freeze

    def initialize(from: 30.days.ago.beginning_of_day, to: Time.current.end_of_day, provider: nil)
      @from = from
      @to = to
      @provider = provider.presence
    end

    def call
      scope = ProviderUsage.in_period(@from..@to).for_provider(@provider).order(:occurred_at)

      CSV.generate do |csv|
        csv << HEADERS
        scope.find_each do |usage|
          csv << [
            usage.id, usage.occurred_at&.iso8601, usage.provider, usage.service_type, usage.model,
            usage.user_id, usage.project_id, usage.video_id,
            usage.input_tokens, usage.output_tokens, usage.generated_images, usage.generated_seconds,
            usage.estimated_cost, usage.currency, usage.pricing_source, usage.provider_request_id
          ]
        end
      end
    end
  end
end
