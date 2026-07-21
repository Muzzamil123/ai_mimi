require "rails_helper"

RSpec.describe BudgetPolicy, type: :model do
  it "validates scope_type, action, and warning percentage" do
    expect(build(:budget_policy, scope_type: "bogus")).not_to be_valid
    expect(build(:budget_policy, action_on_limit: "nope")).not_to be_valid
    expect(build(:budget_policy, warning_percentage: 150)).not_to be_valid
  end

  it "requires a scope_id unless global" do
    expect(build(:budget_policy, scope_type: "user", scope_id: nil)).not_to be_valid
    expect(build(:budget_policy, scope_type: "global", scope_id: nil)).to be_valid
  end

  it "requires at least one limit" do
    expect(build(:budget_policy, daily_limit: nil, monthly_limit: nil)).not_to be_valid
  end

  describe ".applicable" do
    let(:user) { create(:user) }
    let(:project) { create(:project, user: user) }

    it "returns the global, the user's, and the project's enabled policies" do
      global = create(:budget_policy, scope_type: "global")
      mine = create(:budget_policy, scope_type: "user", scope_id: user.id)
      theirs = create(:budget_policy, scope_type: "user", scope_id: create(:user).id)
      proj = create(:budget_policy, scope_type: "project", scope_id: project.id)
      create(:budget_policy, scope_type: "global", enabled: false)

      result = BudgetPolicy.applicable(user: user, project: project)
      expect(result).to include(global, mine, proj)
      expect(result).not_to include(theirs)
    end

    it "filters by provider (a provider-specific policy only matches that provider)" do
      all_providers = create(:budget_policy, scope_type: "global", provider: nil)
      google = create(:budget_policy, scope_type: "global", provider: "google_labs")

      expect(BudgetPolicy.applicable(user: nil, project: nil, provider: "google_labs"))
        .to include(all_providers, google)

      for_openai = BudgetPolicy.applicable(user: nil, project: nil, provider: "openai")
      expect(for_openai).to include(all_providers)
      expect(for_openai).not_to include(google)
    end
  end
end
