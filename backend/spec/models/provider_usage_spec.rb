require "rails_helper"

RSpec.describe ProviderUsage, type: :model do
  it "requires a provider and a known service_type" do
    expect(build(:provider_usage, provider: nil)).not_to be_valid
    expect(build(:provider_usage, service_type: "bogus")).not_to be_valid
  end

  it "rejects a negative cost" do
    expect(build(:provider_usage, estimated_cost: -1)).not_to be_valid
  end

  it "stamps occurred_at on create when absent" do
    usage = create(:provider_usage, occurred_at: nil)
    expect(usage.occurred_at).to be_present
  end

  it "exposes the pricing source and unpriced?" do
    usage = build(:provider_usage, metadata: { "pricing_source" => "unpriced" })
    expect(usage.pricing_source).to eq("unpriced")
    expect(usage).to be_unpriced
  end

  it "enforces one row per source (idempotency key)" do
    prompt = create(:prompt)
    create(:provider_usage, source: prompt)
    dup = build(:provider_usage, source: prompt)
    expect { dup.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end
end
