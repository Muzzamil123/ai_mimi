require "rails_helper"
require "cgi"

RSpec.describe Downloads::SignedUrl do
  include ActiveSupport::Testing::TimeHelpers

  let(:asset) { create(:video_asset, :ready) }

  def token_from(path)
    CGI.unescape(path.split("token=").last)
  end

  it "round-trips an asset download token" do
    path = described_class.asset_path(asset, disposition: "attachment")
    payload = described_class.verify(token_from(path))

    expect(payload[:kind]).to eq("asset")
    expect(payload[:asset_id]).to eq(asset.id)
    expect(payload[:disposition]).to eq("attachment")
  end

  it "mints inline stream and thumbnail tokens" do
    expect(described_class.verify(token_from(described_class.thumbnail_path(asset)))[:kind]).to eq("thumbnail")
    stream = described_class.verify(token_from(described_class.asset_path(asset, disposition: "inline")))
    expect(stream[:disposition]).to eq("inline")
  end

  it "rejects a tampered token" do
    path = described_class.asset_path(asset)
    tampered = "#{token_from(path)}x"
    expect { described_class.verify(tampered) }.to raise_error(described_class::InvalidToken)
  end

  it "rejects an expired token" do
    path = described_class.asset_path(asset, expires_in: 60)
    token = token_from(path)

    travel_to(2.hours.from_now) do
      expect { described_class.verify(token) }.to raise_error(described_class::InvalidToken)
    end
  end
end
