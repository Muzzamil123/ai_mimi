require "digest"

FactoryBot.define do
  factory :video_asset do
    association :video_generation, factory: %i[video_generation completed]
    sequence(:storage_key) { |n| "videos/assets/#{n}/output.mp4" }
    filename { "output.mp4" }
    mime_type { "video/mp4" }
    width { 720 }
    height { 960 }
    duration_seconds { 15 }
    file_size { 2048 }
    sequence(:checksum) { |n| Digest::SHA256.hexdigest("asset-#{n}") }
    validation_status { :pending }

    trait :ready do
      validation_status { :valid }
      stored_at { Time.current }
      sequence(:thumbnail_storage_key) { |n| "videos/assets/#{n}/thumb.jpg" }
    end

    trait :invalid do
      validation_status { :invalid }
    end

    trait :failed do
      validation_status { :failed }
    end
  end
end
