FactoryBot.define do
  factory :character_image do
    association :character
    sequence(:storage_key) { |n| "characters/test/#{n}/source.png" }
    original_filename { "character.png" }
    mime_type { "image/png" }
    width { 1 }
    height { 1 }
    file_size { 128 }
    checksum { "0" * 64 }
    provider_asset_id { "fake-asset-1" }
  end
end
