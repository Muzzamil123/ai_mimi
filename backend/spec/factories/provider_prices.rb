FactoryBot.define do
  factory :provider_price do
    provider { "openai" }
    service_type { "text_generation" }
    model { "" }
    per_input_token { "0.00000015" }
    per_output_token { "0.00000060" }
    currency { "USD" }
    enabled { true }

    trait :video do
      provider { "google_labs" }
      service_type { "video_generation" }
      model { "" }
      per_input_token { nil }
      per_output_token { nil }
      per_second { "0.05" }
    end

    trait :image do
      provider { "gemini" }
      service_type { "character_image" }
      model { "" }
      per_input_token { nil }
      per_output_token { nil }
      per_image { "0.04" }
    end
  end
end
