require "rails_helper"

RSpec.describe "Admin Audit Logs API", type: :request do
  let(:admin) { create(:user, :admin) }

  it_behaves_like "an admin-only endpoint", :get, "/api/v1/admin/audit_logs"

  describe "GET /api/v1/admin/audit_logs" do
    it "lists entries newest-first with an actor label" do
      create(:audit_log, actor: admin, action: "user.suspend")

      get "/api/v1/admin/audit_logs", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      row = response.parsed_body["audit_logs"].first
      expect(row).to include("action", "resource_type", "metadata", "ip_address")
      expect(row["actor_label"]).to eq(admin.email)
    end

    it "filters by action_name (action is reserved by Rails routing)" do
      create(:audit_log, action: "user.suspend")
      create(:audit_log, action: "settings.update", resource_type: "PlatformSetting")

      get "/api/v1/admin/audit_logs", params: { action_name: "settings.update" },
                                      headers: auth_headers(admin)

      actions = response.parsed_body["audit_logs"].map { |l| l["action"] }
      expect(actions).to all(eq("settings.update"))
    end
  end
end
