require "rails_helper"

RSpec.describe "Admin Costs API", type: :request do
  let(:admin) { create(:user, :admin) }

  it_behaves_like "an admin-only endpoint", :get, "/api/v1/admin/costs"

  describe "GET /api/v1/admin/costs" do
    it "returns the aggregated cost dashboard" do
      create(:provider_usage, :video_generation, estimated_cost: "3.00")
      create(:provider_usage, estimated_cost: "0.5")

      get "/api/v1/admin/costs", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["totals"]["estimated_cost"]).to eq(3.5)
      expect(body["by_provider"]).to be_an(Array)
      expect(body["by_day"]).to be_an(Array)
    end
  end

  describe "GET /api/v1/admin/costs/users and /projects" do
    it "returns spend tables" do
      user = create(:user, email: "spender@example.com")
      create(:provider_usage, user: user, estimated_cost: "5")

      get "/api/v1/admin/costs/users", headers: auth_headers(admin)
      expect(response.parsed_body["rows"].first).to include("label" => "spender@example.com")

      get "/api/v1/admin/costs/projects", headers: auth_headers(admin)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/admin/costs/export" do
    it "streams a CSV of the ledger" do
      create(:provider_usage, provider: "openai", estimated_cost: "0.5")

      get "/api/v1/admin/costs/export", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/csv")
      expect(response.body).to include("provider,service_type")
      expect(response.body).to include("openai")
    end
  end
end
