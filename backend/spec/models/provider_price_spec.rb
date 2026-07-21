require "rails_helper"

RSpec.describe ProviderPrice, type: :model do
  it "normalizes a nil model to an empty string (single default row)" do
    price = create(:provider_price, model: nil)
    expect(price.model).to eq("")
  end

  it "requires a known service_type and is unique per provider/service/model" do
    create(:provider_price, provider: "openai", service_type: "text_generation", model: "")
    dup = build(:provider_price, provider: "openai", service_type: "text_generation", model: "")
    expect(dup).not_to be_valid
    expect(build(:provider_price, service_type: "bogus")).not_to be_valid
  end

  describe ".lookup" do
    it "prefers a model-specific row over the provider/service default" do
      default = create(:provider_price, provider: "openai", service_type: "text_generation", model: "")
      specific = create(:provider_price, provider: "openai", service_type: "text_generation", model: "gpt-4o")

      expect(ProviderPrice.lookup(provider: "openai", service_type: "text_generation", model: "gpt-4o")).to eq(specific)
      expect(ProviderPrice.lookup(provider: "openai", service_type: "text_generation", model: "other")).to eq(default)
      expect(ProviderPrice.lookup(provider: "openai", service_type: "text_generation")).to eq(default)
    end

    it "ignores disabled rows and returns nil when nothing matches" do
      create(:provider_price, provider: "openai", service_type: "text_generation", model: "", enabled: false)
      expect(ProviderPrice.lookup(provider: "openai", service_type: "text_generation")).to be_nil
    end
  end
end
