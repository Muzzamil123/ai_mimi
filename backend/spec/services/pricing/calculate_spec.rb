require "rails_helper"

RSpec.describe Pricing::Calculate, type: :service do
  it "sums per-unit rates for the configured price" do
    create(:provider_price, provider: "openai", service_type: "text_generation", model: "",
                            per_input_token: "0.00000015", per_output_token: "0.00000060")

    result = described_class.call(
      provider: "openai", service_type: "text_generation",
      units: { input_tokens: 1000, output_tokens: 500 }
    )

    expect(result).to be_configured
    # 1000 * 0.00000015 + 500 * 0.00000060 = 0.00015 + 0.0003 = 0.00045
    expect(result.amount).to eq(BigDecimal("0.00045"))
    expect(result.currency).to eq("USD")
  end

  it "multiplies per-second video pricing" do
    create(:provider_price, :video, per_second: "0.05")
    result = described_class.call(provider: "google_labs", service_type: "video_generation",
                                  units: { generated_seconds: 15 })
    expect(result.amount).to eq(BigDecimal("0.75"))
  end

  it "reports not-configured when no price row matches" do
    result = described_class.call(provider: "google_labs", service_type: "video_generation",
                                  units: { generated_seconds: 15 })
    expect(result).not_to be_configured
    expect(result.amount).to be_nil
  end
end
