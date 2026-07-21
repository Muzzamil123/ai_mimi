require "rails_helper"

RSpec.describe "Admin Health API", type: :request do
  let(:admin) { create(:user, :admin) }

  it_behaves_like "an admin-only endpoint", :get, "/api/v1/admin/health"

  describe "GET /api/v1/admin/health" do
    it "returns a health snapshot (always 200 behind admin auth)" do
      get "/api/v1/admin/health", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include("status", "components", "version")
    end
  end
end
