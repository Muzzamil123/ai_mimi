FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    name { "Test User" }
    password { "password123" }
    role { :user }
    status { :active }

    trait :admin do
      role { :admin }
    end

    trait :verified do
      email_verified_at { Time.current }
    end

    trait :suspended do
      status { :suspended }
    end
  end
end
