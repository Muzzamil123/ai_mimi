FactoryBot.define do
  factory :video_generation do
    video { association(:video, :with_idea) }
    project { video.project }
    character { association(:character, :approved, project: video.project) }
    prompt { association(:prompt, :approved, video: video) }
    aspect_ratio { "3:4" }
    variation_number { 1 }
    duration_seconds { 15 }
    provider { "fake" }
    provider_model { "fake-video-1" }
    status { :pending }
    # A stable-but-unique placeholder; the real batch computes a deterministic key.
    sequence(:idempotency_key) { |n| "test-key-#{n}" }

    trait :processing do
      status { :processing }
      provider_job_id { "fake-job-1" }
      progress { 40 }
      started_at { Time.current }
    end

    trait :completed do
      status { :completed }
      provider_job_id { "fake-job-1" }
      progress { 100 }
      started_at { Time.current }
      completed_at { Time.current }
    end

    trait :failed do
      status { :failed }
      error_code { "provider_error" }
      error_message { "boom" }
    end

    trait :cancelled do
      status { :cancelled }
    end
  end
end
