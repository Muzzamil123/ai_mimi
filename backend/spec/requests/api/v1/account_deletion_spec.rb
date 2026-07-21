require "rails_helper"

RSpec.describe "DELETE /api/v1/me (account deletion)", type: :request do
  include ActiveJob::TestHelper

  it "soft-deletes, revokes sessions, enqueues the purge, and audits" do
    user = create(:user)
    token = create(:refresh_token, user: user, expires_at: 1.day.from_now)

    expect {
      delete "/api/v1/me", headers: auth_headers(user)
    }.to change(AuditLog, :count).by(1)
      .and have_enqueued_job(PurgeAccountJob).with(user.id)

    expect(response).to have_http_status(:no_content)
    expect(user.reload).to be_status_deleted
    expect(token.reload.revoked_at).to be_present

    log = AuditLog.last
    expect(log.action).to eq("account.deletion_requested")
    expect(log.actor).to eq(user)
  end

  it "requires authentication" do
    delete "/api/v1/me"
    expect(response).to have_http_status(:unauthorized)
  end
end
