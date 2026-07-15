require "securerandom"

FactoryBot.define do
  factory :character do
    association :project
    sequence(:name) { |n| "Character #{n}" }
    description { "A friendly animated mascot" }
    character_attributes { { "species" => "fox", "mood" => "cheerful" } }
    style_preferences { { "palette" => "warm" } }
    status { :pending }

    trait :generating do
      status { :generating }
      generation_id { SecureRandom.uuid }
      generation_prompt { "Draw a cheerful fox mascot" }
    end

    trait :awaiting_approval do
      status { :awaiting_approval }
      generation_id { SecureRandom.uuid }
      generation_prompt { "Draw a cheerful fox mascot" }
      provider { "fake" }
      provider_model { "fake-image-1" }
    end

    trait :approved do
      status { :approved }
      approved_at { Time.current }
      locked_at { Time.current }
    end

    trait :rejected do
      status { :rejected }
      rejected_at { Time.current }
      rejection_feedback { "Make it friendlier" }
    end

    trait :failed do
      status { :failed }
      generation_id { SecureRandom.uuid }
      failure_reason { "provider exploded" }
    end

    trait :with_image do
      after(:create) do |character|
        create(:character_image, character: character)
      end
    end
  end
end
