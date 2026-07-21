require "rails_helper"

RSpec.describe "Admin Settings API", type: :request do
  let(:admin) { create(:user, :admin) }

  it_behaves_like "an admin-only endpoint", :get, "/api/v1/admin/settings"

  describe "GET /api/v1/admin/settings" do
    it "returns the registry snapshot with secret values masked" do
      PlatformSetting.set("openai_api_key", "sk-secret")

      get "/api/v1/admin/settings", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      secret = response.parsed_body["settings"].find { |s| s["key"] == "openai_api_key" }
      expect(secret["configured"]).to be(true)
      expect(secret["value"]).to be_nil
      expect(response.body).not_to include("sk-secret")
    end
  end

  describe "PATCH /api/v1/admin/settings" do
    it "updates settings, audits the keys (never the values), and masks secrets" do
      expect {
        patch "/api/v1/admin/settings",
              params: { settings: { email_sender_name: "Studio", openai_api_key: "sk-new-secret" } },
              headers: auth_headers(admin)
      }.to change(AuditLog, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(PlatformSetting.get("email_sender_name")).to eq("Studio")
      expect(PlatformSetting.get("openai_api_key")).to eq("sk-new-secret")
      expect(response.body).not_to include("sk-new-secret")

      log = AuditLog.last
      expect(log.action).to eq("settings.update")
      expect(log.metadata["keys"]).to contain_exactly("email_sender_name", "openai_api_key")
      expect(log.metadata.to_json).not_to include("sk-new-secret")
    end

    it "rejects an unknown key (422)" do
      patch "/api/v1/admin/settings", params: { settings: { bogus: "x" } },
                                      headers: auth_headers(admin)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_operation")
    end
  end
end
