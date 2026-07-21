require "rails_helper"

# Phase 13: sensitive user actions (not just admin operations) are audited.
RSpec.describe "Audit coverage for sensitive actions", type: :request do
  it "records a failed login attempt (no secrets)" do
    create(:user, email: "victim@example.com", password: "password123")

    expect {
      post "/api/v1/auth/login", params: { email: "victim@example.com", password: "wrong" }
    }.to change { AuditLog.where(action: "auth.login_failed").count }.by(1)

    expect(response).to have_http_status(:unauthorized)
    log = AuditLog.find_by(action: "auth.login_failed")
    expect(log.metadata["email"]).to eq("victim@example.com")
    expect(log.metadata.to_json).not_to include("wrong") # never log the password
  end

  it "records a completed password reset" do
    user = create(:user)
    token = user.generate_token_for(:password_reset)

    expect {
      post "/api/v1/auth/password/reset", params: { token: token, password: "new-password-123" }
    }.to change { AuditLog.where(action: "auth.password_reset").count }.by(1)

    expect(response).to have_http_status(:no_content)
    expect(AuditLog.find_by(action: "auth.password_reset").actor).to eq(user)
  end
end
