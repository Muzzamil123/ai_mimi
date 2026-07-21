require "rails_helper"

RSpec.describe Costs::EstimateGeneration, type: :service do
  let(:video) { ready_to_generate_video }
  let(:provider) { VideoGenerationProviders.default_provider }

  it "estimates the four-variant batch from the per-second video price" do
    create(:provider_price, provider: provider, service_type: "video_generation", model: "",
                            per_input_token: nil, per_output_token: nil, per_second: "0.05")

    estimate = described_class.call(video)

    expect(estimate).to be_configured
    expect(estimate.variant_count).to eq(4)
    expect(estimate.duration_seconds).to eq(15)
    expect(estimate.per_variant).to eq(BigDecimal("0.75")) # 15s * 0.05
    expect(estimate.total).to eq(BigDecimal("3.00"))       # 4 * 0.75
  end

  it "reports unconfigured when video pricing is not set up" do
    estimate = described_class.call(video)
    expect(estimate).not_to be_configured
    expect(estimate.total).to be_nil
  end
end
