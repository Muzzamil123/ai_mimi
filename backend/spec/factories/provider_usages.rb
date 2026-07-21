FactoryBot.define do
  factory :provider_usage do
    association :user
    provider { "openai" }
    service_type { "text_generation" }
    model { "gpt-4o-mini" }
    input_tokens { 100 }
    output_tokens { 200 }
    estimated_cost { "0.0025" }
    currency { "USD" }
    occurred_at { Time.current }
    metadata { { "pricing_source" => "configured" } }

    trait :video_generation do
      provider { "google_labs" }
      service_type { "video_generation" }
      model { "veo" }
      input_tokens { nil }
      output_tokens { nil }
      generated_seconds { 15 }
      estimated_cost { "0.50" }
    end

    trait :character_image do
      provider { "gemini" }
      service_type { "character_image" }
      model { "imagen" }
      input_tokens { nil }
      output_tokens { nil }
      generated_images { 1 }
      estimated_cost { "0.04" }
    end
  end
end
