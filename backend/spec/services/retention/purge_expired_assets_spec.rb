require "rails_helper"

RSpec.describe Retention::PurgeExpiredAssets, type: :service do
  before { PlatformSetting.set("file_retention_days", "30") }

  it "purges assets older than the retention window and deletes their blobs" do
    old = create(:video_asset, :ready, created_at: 40.days.ago)
    recent = create(:video_asset, :ready, created_at: 5.days.ago)
    Storage.adapter.store(key: old.storage_key, data: "x", content_type: "video/mp4")

    count = described_class.call

    expect(count).to eq(1)
    expect(VideoAsset.exists?(old.id)).to be(false)
    expect(VideoAsset.exists?(recent.id)).to be(true)
    expect(Storage.adapter.exist?(old.storage_key)).to be(false)
  end

  it "does not delete a stored blob still referenced by another asset (dedupe-safe)" do
    shared_key = "videos/assets/shared/output.mp4"
    Storage.adapter.store(key: shared_key, data: "x", content_type: "video/mp4")
    old = create(:video_asset, :ready, created_at: 40.days.ago, storage_key: shared_key)
    create(:video_asset, :ready, created_at: 5.days.ago, storage_key: shared_key)

    described_class.call

    expect(VideoAsset.exists?(old.id)).to be(false)
    expect(Storage.adapter.exist?(shared_key)).to be(true) # still used by the recent asset
  end

  it "is a no-op when retention is disabled (0 days)" do
    PlatformSetting.set("file_retention_days", "0")
    create(:video_asset, :ready, created_at: 100.days.ago)
    expect(described_class.call).to eq(0)
  end
end
