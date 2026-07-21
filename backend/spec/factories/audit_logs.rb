FactoryBot.define do
  factory :audit_log do
    association :actor, factory: %i[user admin]
    action { "user.suspend" }
    resource_type { "User" }
    sequence(:resource_id) { |n| n }
    metadata { { "reason" => "policy violation" } }
    ip_address { "203.0.113.10" }
    user_agent { "RSpec" }
  end
end
