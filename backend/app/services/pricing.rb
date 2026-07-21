# Namespace for cost calculation from configurable ProviderPrice rows. Keeps the
# "what does a call cost" logic in one place so pricing can change without a
# deploy and without touching provider adapters (Phase 12).
module Pricing
  # Outcome of a price calculation. `configured` is false when no matching
  # ProviderPrice exists (caller may fall back to a provider-reported cost).
  Result = Struct.new(:amount, :currency, :configured, keyword_init: true) do
    def configured?
      configured
    end
  end
end
