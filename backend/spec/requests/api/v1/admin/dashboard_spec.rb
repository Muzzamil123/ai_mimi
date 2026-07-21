require "rails_helper"

RSpec.describe "Admin Dashboard API", type: :request do
  let(:admin) { create(:user, :admin) }

  it_behaves_like "an admin-only endpoint", :get, "/api/v1/admin/dashboard"

  describe "GET /api/v1/admin/dashboard" do
    it "returns counts by status, totals, and a health snapshot" do
      create(:project, :ready)
      create(:video_generation, :failed)

      get "/api/v1/admin/dashboard", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["projects"]).to include("ready")
      expect(body["totals"]).to include("users", "failed_generations")
      expect(body["totals"]["failed_generations"]).to eq(1)
      expect(body["health"]).to include("status", "components")
    end
  end
end
