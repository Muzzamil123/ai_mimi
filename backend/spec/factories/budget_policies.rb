FactoryBot.define do
  factory :budget_policy do
    scope_type { "global" }
    scope_id { nil }
    provider { nil }
    monthly_limit { "100.00" }
    warning_percentage { 80 }
    action_on_limit { "warn" }
    enabled { true }

    trait :block do
      action_on_limit { "block" }
    end

    trait :daily do
      daily_limit { "10.00" }
      monthly_limit { nil }
    end

    trait :user_scope do
      scope_type { "user" }
      scope_id { create(:user).id }
    end

    trait :project_scope do
      scope_type { "project" }
      scope_id { create(:project).id }
    end
  end
end
