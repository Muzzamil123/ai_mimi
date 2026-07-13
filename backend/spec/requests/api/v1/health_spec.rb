require "rails_helper"

RSpec.describe "GET /api/v1/health", type: :request do
  it "returns 200 with the expected health schema when dependencies are up" do
    get "/api/v1/health"

    expect(response).to have_http_status(:ok)

    body = response.parsed_body
    expect(body).to include("status", "version", "timestamp", "components")
    expect(body["status"]).to eq("ok")
    expect(body["version"]).to eq(Rails.application.config.x.app_version)

    components = body["components"]
    expect(components).to include("database", "redis", "sidekiq")
    expect(components["database"]).to eq("ok")
    %w[database redis sidekiq].each do |component|
      expect(%w[ok error]).to include(components[component])
    end
  end

  it "returns 503 when a dependency is unreachable" do
    degraded = Health::Report.new(
      version: "test",
      components: { database: "ok", redis: "error", sidekiq: "ok" },
    )
    allow(Health::CheckService).to receive(:call).and_return(degraded)

    get "/api/v1/health"

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body["status"]).to eq("degraded")
  end
end
