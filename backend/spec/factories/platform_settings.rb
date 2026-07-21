FactoryBot.define do
  factory :platform_setting do
    key { "email_sender_name" }
    value { "AI Video Platform" }

    trait :secret do
      key { "openai_api_key" }
      value { "sk-test-secret" }
    end

    trait :maintenance_mode do
      key { "maintenance_mode" }
      value { "true" }
    end
  end
end
