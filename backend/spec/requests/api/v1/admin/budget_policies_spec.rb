require "rails_helper"

RSpec.describe "Admin Budget Policies API", type: :request do
  let(:admin) { create(:user, :admin) }

  it_behaves_like "an admin-only endpoint", :get, "/api/v1/admin/budget_policies"

  describe "POST /api/v1/admin/budget_policies" do
    it "creates a policy and audits it" do
      expect {
        post "/api/v1/admin/budget_policies",
             params: { budget_policy: {
               scope_type: "global", monthly_limit: "500", action_on_limit: "block", warning_percentage: 75
             } },
             headers: auth_headers(admin)
      }.to change(BudgetPolicy, :count).by(1).and change(AuditLog, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(AuditLog.last.action).to eq("budget_policy.create")
    end

    it "rejects a policy with no limit (422)" do
      post "/api/v1/admin/budget_policies",
           params: { budget_policy: { scope_type: "global", action_on_limit: "warn" } },
           headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH/DELETE" do
    it "updates and deletes with audit" do
      policy = create(:budget_policy)
      patch "/api/v1/admin/budget_policies/#{policy.id}",
            params: { budget_policy: { enabled: false } }, headers: auth_headers(admin)
      expect(policy.reload.enabled).to be(false)

      expect {
        delete "/api/v1/admin/budget_policies/#{policy.id}", headers: auth_headers(admin)
      }.to change(BudgetPolicy, :count).by(-1)
      expect(AuditLog.where(action: "budget_policy.delete")).to exist
    end
  end
end
