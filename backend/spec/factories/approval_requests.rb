require "securerandom"

FactoryBot.define do
  factory :approval_request do
    project
    user { project.user }
    character { association(:character, :awaiting_approval, project: project) }
    recipient_email { user.email }
    token_digest { ApprovalRequest.digest(SecureRandom.hex(24)) }
    status { :pending }
    expires_at { 72.hours.from_now }

    # Still pending but past its window (the effective-expired case).
    trait :past_expiry do
      status { :pending }
      expires_at { 1.hour.ago }
    end

    trait :expired do
      status { :expired }
      expires_at { 1.hour.ago }
    end

    trait :approved do
      status { :approved }
      responded_at { Time.current }
    end

    trait :rejected do
      status { :rejected }
      feedback { "make it friendlier" }
      responded_at { Time.current }
    end

    trait :cancelled do
      status { :cancelled }
    end
  end
end
