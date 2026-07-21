require "securerandom"

FactoryBot.define do
  factory :email_delivery do
    association :user
    email_type { "video_generation_completed" }
    recipient { user.email }
    subject { "Your video is ready" }
    provider { "test" }
    status { :sent }
    sent_at { Time.current }
    sequence(:dedupe_key) { |n| "video_generation_completed:#{n}" }

    trait :queued do
      status { :queued }
      sent_at { nil }
    end

    trait :failed do
      status { :failed }
      sent_at { nil }
      error_message { "SMTP timeout" }
    end

    trait :unread do
      read_at { nil }
    end

    trait :read do
      read_at { Time.current }
    end
  end
end
