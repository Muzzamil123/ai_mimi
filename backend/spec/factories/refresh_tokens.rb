require "securerandom"

FactoryBot.define do
  factory :refresh_token do
    association :user
    sequence(:token_digest) { |n| RefreshToken.digest("raw-token-#{n}-#{SecureRandom.hex(4)}") }
    expires_at { 30.days.from_now }
  end
end
