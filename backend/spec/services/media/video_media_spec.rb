require "rails_helper"

RSpec.describe Media::VideoInfo::Fake do
  subject(:inspector) { described_class.new }

  it "parses the fake container header" do
    result = inspector.probe("FAKEVID;duration=15;width=720;height=960;rest".b)
    expect(result).to be_playable
    expect(result.duration_seconds).to eq(15)
    expect(result.width).to eq(720)
    expect(result.height).to eq(960)
  end

  it "reports unplayable for bytes without the header" do
    expect(inspector.probe("not a video".b)).not_to be_playable
  end
end

RSpec.describe Media::Thumbnail::Fake do
  it "returns valid JPEG bytes" do
    data = described_class.new.generate("anything".b)
    expect(data[0, 2].b).to eq("\xFF\xD8".b) # JPEG SOI marker
  end
end

RSpec.describe Media::VideoInfo do
  it "defaults to the fake backend off-production" do
    expect(described_class.build).to be_a(Media::VideoInfo::Fake)
  end
end
