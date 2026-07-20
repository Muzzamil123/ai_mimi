require "rails_helper"

RSpec.describe VideoAsset do
  it "is valid with the factory" do
    expect(build(:video_asset)).to be_valid
  end

  describe "#ready?" do
    it "is true only when validated and stored" do
      expect(build(:video_asset, :ready)).to be_ready
      expect(build(:video_asset, validation_status: :valid, stored_at: nil)).not_to be_ready
      expect(build(:video_asset, validation_status: :pending, stored_at: Time.current)).not_to be_ready
    end
  end

  describe "status prefix" do
    it "uses a validation_ prefix so AR #valid? is preserved" do
      asset = build(:video_asset, validation_status: :valid)
      expect(asset.validation_valid?).to be(true)
      expect(asset.valid?).to be(true) # ActiveRecord validity, not the status
    end
  end

  it "reports duplicates" do
    original = create(:video_asset, :ready)
    dup = build(:video_asset, duplicate_of: original)
    expect(dup).to be_duplicate
  end
end
