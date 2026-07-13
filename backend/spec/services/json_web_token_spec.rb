require "rails_helper"

RSpec.describe JsonWebToken do
  it "encodes and decodes a payload with standard claims" do
    token = described_class.encode({ sub: 42, role: "user", type: "access" })
    payload = described_class.decode(token)

    expect(payload[:sub]).to eq(42)
    expect(payload[:type]).to eq("access")
    expect(payload[:jti]).to be_present
    expect(payload[:exp]).to be_present
  end

  it "returns nil for a tampered token" do
    token = described_class.encode({ sub: 1 })
    expect(described_class.decode("#{token}tampered")).to be_nil
  end

  it "returns nil for an expired token" do
    token = described_class.encode({ sub: 1 }, exp: 1.hour.ago)
    expect(described_class.decode(token)).to be_nil
  end

  it "returns nil for blank input" do
    expect(described_class.decode(nil)).to be_nil
    expect(described_class.decode("")).to be_nil
  end
end
