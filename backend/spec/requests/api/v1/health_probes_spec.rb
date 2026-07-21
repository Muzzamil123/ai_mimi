require "rails_helper"

RSpec.describe "Health probes & request id", type: :request do
  describe "GET /api/v1/health/live" do
    it "always returns 200 without checking dependencies" do
      get "/api/v1/health/live"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("ok")
    end
  end

  describe "GET /api/v1/health/ready" do
    it "reports readiness with database and redis components" do
      get "/api/v1/health/ready"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["components"]).to include("database", "redis")
    end
  end

  it "echoes an X-Request-Id header on API responses" do
    get "/api/v1/health/live"
    expect(response.headers["X-Request-Id"]).to be_present
  end
end
