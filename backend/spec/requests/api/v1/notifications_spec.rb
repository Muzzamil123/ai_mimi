require "rails_helper"
require "openssl"

RSpec.describe "Notifications API", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe "GET /api/v1/notifications" do
    it "lists the user's notifications with an unread count" do
      create(:email_delivery, :unread, user: user, dedupe_key: "a")
      create(:email_delivery, :read, user: user, dedupe_key: "b")
      create(:email_delivery, user: create(:user), dedupe_key: "other") # another user's

      get "/api/v1/notifications", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["notifications"].size).to eq(2)
      expect(response.parsed_body["meta"]["unread_count"]).to eq(1)
    end

    it "requires authentication" do
      get "/api/v1/notifications"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/notifications/read" do
    it "marks all unread as read" do
      create_list(:email_delivery, 3, :unread, user: user)

      post "/api/v1/notifications/read", headers: headers

      expect(response.parsed_body["unread_count"]).to eq(0)
      expect(user.email_deliveries.unread.count).to eq(0)
    end

    it "marks only the given ids" do
      keep = create(:email_delivery, :unread, user: user, dedupe_key: "keep")
      mark = create(:email_delivery, :unread, user: user, dedupe_key: "mark")

      post "/api/v1/notifications/read", params: { ids: [ mark.id ] }, headers: headers

      expect(mark.reload.read?).to be(true)
      expect(keep.reload.read?).to be(false)
    end
  end

  describe "POST /api/v1/notifications/:id/retry" do
    it "retries a failed notification" do
      delivery = create(:email_delivery, :failed, user: user, dedupe_key: "f")

      expect {
        post "/api/v1/notifications/#{delivery.id}/retry", headers: headers
      }.to have_enqueued_job(RetryEmailDeliveryJob).with(delivery.id)

      expect(response).to have_http_status(:accepted)
    end

    it "refuses to retry a non-failed notification" do
      delivery = create(:email_delivery, status: :sent, user: user, dedupe_key: "s")

      post "/api/v1/notifications/#{delivery.id}/retry", headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "hides another user's notification (404)" do
      delivery = create(:email_delivery, :failed, user: create(:user), dedupe_key: "x")

      post "/api/v1/notifications/#{delivery.id}/retry", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "notification preferences" do
    it "shows optional types with current values" do
      get "/api/v1/me/notification_preferences", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["preferences"]).to include("prompt_ready" => true)
    end

    it "updates an optional preference" do
      patch "/api/v1/me/notification_preferences",
            params: { preferences: { prompt_ready: false } }, headers: headers

      expect(response.parsed_body["preferences"]["prompt_ready"]).to be(false)
      expect(user.reload.email_type_enabled?("prompt_ready")).to be(false)
    end
  end

  describe "email delivery webhook" do
    let(:secret) { "email-shh" }
    let(:path) { "/api/v1/webhooks/email_deliveries" }

    around do |example|
      original = ENV["EMAIL_WEBHOOK_SECRET"]
      ENV["EMAIL_WEBHOOK_SECRET"] = secret
      example.run
      ENV["EMAIL_WEBHOOK_SECRET"] = original
    end

    it "rejects a bad signature" do
      body = { message_id: "m1", event: "delivered" }.to_json
      post path, params: body, headers: { "CONTENT_TYPE" => "application/json", "X-Signature" => "bad" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "accepts a signed webhook and updates the delivery" do
      delivery = create(:email_delivery, provider_message_id: "m1")
      body = { message_id: "m1", event: "delivered" }.to_json
      signature = OpenSSL::HMAC.hexdigest("SHA256", secret, body)

      perform_enqueued_jobs do
        post path, params: body, headers: { "CONTENT_TYPE" => "application/json", "X-Signature" => signature }
      end

      expect(response).to have_http_status(:accepted)
      expect(delivery.reload).to be_delivered
    end
  end
end
