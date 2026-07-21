require "rails_helper"

RSpec.describe Admin::UpdateSettings, type: :service do
  it "upserts known settings and returns the changed keys" do
    changed = described_class.call(
      "email_sender_name" => "Studio",
      "maintenance_mode" => "true"
    )

    expect(changed).to contain_exactly("email_sender_name", "maintenance_mode")
    expect(PlatformSetting.get("email_sender_name")).to eq("Studio")
    expect(PlatformSetting.get("maintenance_mode")).to be(true)
  end

  it "rejects unknown keys without persisting anything" do
    expect {
      described_class.call("email_sender_name" => "Studio", "bogus" => "x")
    }.to raise_error(Admin::InvalidOperation, /bogus/)

    expect(PlatformSetting.where(key: "email_sender_name")).to be_empty
  end
end
