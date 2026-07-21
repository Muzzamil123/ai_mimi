module Costs
  # Estimates what generating a video's outputs will cost, before the user
  # commits — the four required variants at the configured per-second video
  # price. `configured: false` means video pricing isn't set up, so the amount
  # is unknown (the UI shows "estimate unavailable" rather than a wrong number).
  class EstimateGeneration < ApplicationService
    Estimate = Struct.new(:currency, :variant_count, :duration_seconds, :per_variant, :total, :configured,
                          keyword_init: true) do
      def configured?
        configured
      end
    end

    def initialize(video, provider: nil)
      @video = video
      @provider = provider || VideoGenerationProviders.default_provider
    end

    def call
      variant_count = VideoGenerations.variant_matrix.size
      duration = Video::DEFAULT_DURATION_SECONDS

      priced = Pricing::Calculate.call(
        provider: @provider,
        service_type: "video_generation",
        units: { generated_seconds: duration, requests: 1 }
      )

      per_variant = priced.configured? ? priced.amount : nil
      total = per_variant ? per_variant * variant_count : nil

      Estimate.new(
        currency: priced.currency,
        variant_count: variant_count,
        duration_seconds: duration,
        per_variant: per_variant,
        total: total,
        configured: priced.configured?
      )
    end
  end
end
