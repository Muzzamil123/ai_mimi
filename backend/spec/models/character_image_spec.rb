require "rails_helper"

RSpec.describe CharacterImage, type: :model do
  it "is valid with required attributes" do
    expect(build(:character_image)).to be_valid
  end

  it "requires a storage_key" do
    image = build(:character_image, storage_key: nil)
    expect(image).not_to be_valid
    expect(image.errors[:storage_key]).to be_present
  end

  it "requires a unique storage_key" do
    create(:character_image, storage_key: "characters/1/x.png")
    dup = build(:character_image, storage_key: "characters/1/x.png")
    expect(dup).not_to be_valid
  end

  it "requires a mime_type" do
    expect(build(:character_image, mime_type: nil)).not_to be_valid
  end

  it "rejects a non-positive file size" do
    expect(build(:character_image, file_size: 0)).not_to be_valid
  end
end
