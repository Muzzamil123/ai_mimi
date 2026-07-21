require "rails_helper"

RSpec.describe Budgets::Evaluate, type: :service do
  let(:user) { create(:user) }

  it "returns ok when there are no policies" do
    result = described_class.call(user: user, project: nil, prospective_cost: 5)
    expect(result.status).to eq("ok")
    expect(result).not_to be_blocked
  end

  it "warns when projected spend crosses the warning threshold" do
    create(:budget_policy, scope_type: "global", monthly_limit: "10", warning_percentage: 80)
    create(:provider_usage, user: user, estimated_cost: "7", occurred_at: Time.current)

    result = described_class.call(user: user, project: nil, prospective_cost: 1) # 8 of 10 = 80%
    expect(result.status).to eq("warning")
    expect(result).not_to be_blocked
  end

  it "blocks when a hard (block) monthly limit would be exceeded" do
    create(:budget_policy, :block, scope_type: "global", monthly_limit: "10")
    create(:provider_usage, user: user, estimated_cost: "9.50", occurred_at: Time.current)

    result = described_class.call(user: user, project: nil, prospective_cost: 1) # 10.50 > 10
    expect(result.status).to eq("exceeded")
    expect(result).to be_blocked
    expect(result.entries.first).to include(level: "exceeded", hard: true, period: "monthly")
  end

  it "does not block a soft (warn) policy that is exceeded" do
    create(:budget_policy, scope_type: "global", monthly_limit: "10", action_on_limit: "warn")
    create(:provider_usage, user: user, estimated_cost: "20", occurred_at: Time.current)

    result = described_class.call(user: user, project: nil, prospective_cost: 1)
    expect(result.status).to eq("exceeded")
    expect(result).not_to be_blocked
  end

  it "scopes user-policy spend to that user only" do
    create(:budget_policy, :block, scope_type: "user", scope_id: user.id, monthly_limit: "10")
    create(:provider_usage, user: create(:user), estimated_cost: "100", occurred_at: Time.current) # someone else

    result = described_class.call(user: user, project: nil, prospective_cost: 1)
    expect(result).not_to be_blocked
  end

  it "counts only the current period for a daily limit" do
    create(:budget_policy, :block, :daily, scope_type: "global", daily_limit: "10")
    create(:provider_usage, user: user, estimated_cost: "50", occurred_at: 2.days.ago)

    result = described_class.call(user: user, project: nil, prospective_cost: 1)
    expect(result).not_to be_blocked
  end
end
