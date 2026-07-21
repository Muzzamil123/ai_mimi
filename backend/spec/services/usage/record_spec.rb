require "rails_helper"

RSpec.describe Usage::Record, type: :service do
  let(:prompt) { create(:prompt) }
  let(:user) { create(:user) }

  it "uses configured pricing and tags the source as configured" do
    create(:provider_price, provider: "openai", service_type: "text_generation", model: "",
                            per_input_token: "0.00000015", per_output_token: "0.00000060")

    usage = described_class.call(
      source: prompt, provider: "openai", service_type: "text_generation",
      user: user, input_tokens: 1000, output_tokens: 500, provider_reported_cost: "9.99"
    )

    expect(usage.estimated_cost).to eq(BigDecimal("0.00045"))
    expect(usage.pricing_source).to eq("configured")
  end

  it "falls back to the provider-reported cost when unpriced" do
    usage = described_class.call(
      source: prompt, provider: "openai", service_type: "text_generation",
      provider_reported_cost: "0.0025"
    )
    expect(usage.estimated_cost).to eq(BigDecimal("0.0025"))
    expect(usage.pricing_source).to eq("provider_fallback")
  end

  it "records zero and flags unpriced when neither pricing nor a fallback exists" do
    usage = described_class.call(source: prompt, provider: "openai", service_type: "text_generation")
    expect(usage.estimated_cost).to eq(0)
    expect(usage.pricing_source).to eq("unpriced")
  end

  it "is idempotent per source (a retry updates the same row)" do
    expect {
      2.times { described_class.call(source: prompt, provider: "openai", service_type: "text_generation", provider_reported_cost: "1.0") }
    }.to change(ProviderUsage, :count).by(1)
  end
end
