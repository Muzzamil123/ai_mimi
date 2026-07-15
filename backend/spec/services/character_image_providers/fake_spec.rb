require "rails_helper"

RSpec.describe CharacterImageProviders::Fake do
  it "returns a valid PNG and normalized metadata" do
    result = described_class.new.generate(prompt: "a fox")

    expect(result.mime_type).to eq("image/png")
    expect(result.provider).to eq("fake")
    expect(result.image_data.byteslice(0, 8)).to eq("\x89PNG\r\n\x1a\n".b)
    expect(Media::ImageInfo.dimensions(result.image_data).width).to eq(1)
  end

  it "derives a deterministic request id from the prompt" do
    a = described_class.new.generate(prompt: "same")
    b = described_class.new.generate(prompt: "same")
    c = described_class.new.generate(prompt: "different")

    expect(a.provider_request_id).to eq(b.provider_request_id)
    expect(a.provider_request_id).not_to eq(c.provider_request_id)
  end
end
