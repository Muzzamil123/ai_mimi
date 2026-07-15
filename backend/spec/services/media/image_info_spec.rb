require "rails_helper"
require "base64"

RSpec.describe Media::ImageInfo do
  it "reads PNG dimensions" do
    png = Base64.decode64(CharacterImageProviders::Fake::PNG_1PX_BASE64)

    dims = described_class.dimensions(png)

    expect(dims.width).to eq(1)
    expect(dims.height).to eq(1)
  end

  it "reads JPEG dimensions from the SOF0 segment" do
    # FFD8 (SOI) FFC0 (SOF0) 0011 (len 17) 08 (precision) 0020 (h=32) 0030 (w=48)
    jpeg = [ "FFD8FFC000110800200030", "00" * 10 ].join.scan(/../).map { |b| b.hex }.pack("C*")

    dims = described_class.dimensions(jpeg)

    expect(dims.width).to eq(48)
    expect(dims.height).to eq(32)
  end

  it "returns nil dimensions for unrecognized data" do
    dims = described_class.dimensions("not an image")

    expect(dims.width).to be_nil
    expect(dims.height).to be_nil
  end
end
