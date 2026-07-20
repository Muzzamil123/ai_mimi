require "securerandom"

FactoryBot.define do
  factory :prompt do
    association :video, factory: %i[video with_idea]
    sequence(:version) { |n| n }
    content { "A 15-second vertical clip: the mascot waves at the camera, warm lighting." }
    source_idea { "A short clip introducing the mascot." }
    status { :draft }

    trait :generating do
      status { :generating }
      content { nil }
      generation_id { SecureRandom.uuid }
    end

    trait :approved do
      status { :approved }
      provider { "openai" }
      provider_model { "gpt-4o-mini" }
      input_tokens { 120 }
      output_tokens { 200 }
      estimated_cost { 0.0003 }
    end

    trait :superseded do
      status { :superseded }
    end

    trait :failed do
      status { :failed }
      content { nil }
      generation_id { SecureRandom.uuid }
      failure_reason { "provider exploded" }
    end
  end
end
