require "rails_helper"

RSpec.describe "Admin Users API", type: :request do
  let(:admin) { create(:user, :admin) }

  it_behaves_like "an admin-only endpoint", :get, "/api/v1/admin/users"

  describe "GET /api/v1/admin/users" do
    it "lists users with pagination, project counts, filters, and search" do
      create_list(:user, 2)
      target = create(:user, :suspended, email: "flagged@example.com")

      get "/api/v1/admin/users", params: { status: "suspended" }, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["users"].map { |u| u["id"] }).to contain_exactly(target.id)
      expect(body["users"].first).to include("projects_count", "last_login_at")
      expect(body["meta"]).to include("total_count", "total_pages")
    end
  end

  describe "POST /api/v1/admin/users/:id/suspend" do
    it "suspends a user and writes an audit record" do
      user = create(:user)

      expect {
        post "/api/v1/admin/users/#{user.id}/suspend",
             params: { reason: "spam" }, headers: auth_headers(admin)
      }.to change(AuditLog, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(user.reload).to be_status_suspended
      log = AuditLog.last
      expect(log.action).to eq("user.suspend")
      expect(log.actor).to eq(admin)
      expect(log.resource_type).to eq("User")
      expect(log.resource_id).to eq(user.id)
      expect(log.metadata["reason"]).to eq("spam")
    end

    it "rejects self-suspension (422) without an audit record" do
      expect {
        post "/api/v1/admin/users/#{admin.id}/suspend", headers: auth_headers(admin)
      }.not_to change(AuditLog, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_operation")
    end
  end

  describe "POST /api/v1/admin/users/:id/reactivate" do
    it "reactivates a suspended user and audits it" do
      user = create(:user, :suspended)

      expect {
        post "/api/v1/admin/users/#{user.id}/reactivate", headers: auth_headers(admin)
      }.to change(AuditLog, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(user.reload).to be_status_active
      expect(AuditLog.last.action).to eq("user.reactivate")
    end
  end
end
