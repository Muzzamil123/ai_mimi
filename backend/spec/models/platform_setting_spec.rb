require "rails_helper"

RSpec.describe PlatformSetting, type: :model do
  it "rejects keys outside the registry" do
    setting = build(:platform_setting, key: "not_a_real_key")
    expect(setting).not_to be_valid
    expect(setting.errors[:key]).to be_present
  end

  it "enforces one row per key" do
    create(:platform_setting, key: "email_sender_name")
    dup = build(:platform_setting, key: "email_sender_name")
    expect(dup).not_to be_valid
  end

  it "encrypts the value at rest" do
    PlatformSetting.set("openai_api_key", "sk-super-secret")
    raw = PlatformSetting.find_by(key: "openai_api_key").read_attribute_before_type_cast(:value)
    expect(raw).not_to include("sk-super-secret")
    expect(PlatformSetting.get("openai_api_key")).to eq("sk-super-secret")
  end

  describe ".get" do
    it "returns the registry default when unset" do
      expect(PlatformSetting.get("generation_retry_count")).to eq(5)
      expect(PlatformSetting.get("maintenance_mode")).to be(false)
    end

    it "casts stored values to the declared type" do
      PlatformSetting.set("maintenance_mode", "true")
      PlatformSetting.set("generation_retry_count", "9")
      expect(PlatformSetting.get("maintenance_mode")).to be(true)
      expect(PlatformSetting.get("generation_retry_count")).to eq(9)
    end
  end

  describe ".set" do
    it "clears a value back to default when given blank" do
      PlatformSetting.set("email_from_address", "ops@example.com")
      PlatformSetting.set("email_from_address", "")
      expect(PlatformSetting.get("email_from_address")).to be_nil
    end

    it "raises on an unknown key" do
      expect { PlatformSetting.set("bogus", "x") }.to raise_error(ArgumentError)
    end
  end

  describe ".snapshot" do
    it "masks secret values but reports whether they are configured" do
      PlatformSetting.set("openai_api_key", "sk-secret")
      row = PlatformSetting.snapshot.find { |s| s[:key] == "openai_api_key" }
      expect(row[:secret]).to be(true)
      expect(row[:configured]).to be(true)
      expect(row[:value]).to be_nil
    end

    it "returns effective non-secret values" do
      PlatformSetting.set("email_sender_name", "Studio")
      row = PlatformSetting.snapshot.find { |s| s[:key] == "email_sender_name" }
      expect(row[:value]).to eq("Studio")
      expect(row[:secret]).to be(false)
    end
  end
end
