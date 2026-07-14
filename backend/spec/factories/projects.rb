FactoryBot.define do
  factory :project do
    association :user
    sequence(:name) { |n| "Project #{n}" }
    default_language { "english" }
    default_tone { "neutral" }
    target_platforms { [ "instagram_reels" ] }

    trait :ready do
      status { :ready }
    end

    trait :archived do
      status { :archived }
      archived_at { Time.current }
    end
  end
end
