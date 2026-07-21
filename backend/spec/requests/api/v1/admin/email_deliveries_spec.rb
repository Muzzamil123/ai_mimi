require "rails_helper"

RSpec.describe "Admin Email Deliveries API", type: :request do
  include ActiveJob::TestHelper

  let(:admin) { create(:user, :admin) }

  it_behaves_like "an admin-only endpoint", :get, "/api/v1/admin/email_deliveries"

  describe "GET /api/v1/admin/email_deliveries" do
    it "lists deliveries with recipient and diagnostics, filtered by status" do
      failed = create(:email_delivery, :failed)
      create(:email_delivery)

      get "/api/v1/admin/email_deliveries", params: { status: "failed" }, headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body["email_deliveries"]
      expect(body.map { |d| d["id"] }).to contain_exactly(failed.id)
      expect(body.first).to include("recipient", "error_message")
    end
  end

  describe "POST /api/v1/admin/email_deliveries/:id/retry" do
    it "re-enqueues a failed delivery and audits it" do
      delivery = create(:email_delivery, :failed)

      expect {
        post "/api/v1/admin/email_deliveries/#{delivery.id}/retry", headers: auth_headers(admin)
      }.to change(AuditLog, :count).by(1)
        .and have_enqueued_job(RetryEmailDeliveryJob).with(delivery.id)

      expect(response).to have_http_status(:accepted)
      expect(AuditLog.last.action).to eq("email_delivery.retry")
    end

    it "refuses to retry a delivered email (422)" do
      delivery = create(:email_delivery, status: :delivered)

      post "/api/v1/admin/email_deliveries/#{delivery.id}/retry", headers: auth_headers(admin)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_operation")
    end
  end
end
