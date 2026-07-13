require "rails_helper"

RSpec.describe "GET /api/v1/health", type: :request do
  it "returns 200 with the expected schema when all dependencies are healthy" do
    healthy = Health::Report.new(
      version: Rails.application.config.x.app_version,
      components: { database: "ok", redis: "ok", sidekiq: "ok" }
    )
    allow(Health::CheckService).to receive(:call).and_return(healthy)

    get "/api/v1/health"

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body).to include("status", "version", "timestamp", "components")
    expect(body["status"]).to eq("ok")
    expect(body["version"]).to eq(Rails.application.config.x.app_version)
    expect(body["components"]).to eq("database" => "ok", "redis" => "ok", "sidekiq" => "ok")
  end

  it "returns 503 with a degraded status when a dependency is down" do
    degraded = Health::Report.new(
      version: "test",
      components: { database: "ok", redis: "error", sidekiq: "ok" }
    )
    allow(Health::CheckService).to receive(:call).and_return(degraded)

    get "/api/v1/health"

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body["status"]).to eq("degraded")
    expect(response.parsed_body["components"]["redis"]).to eq("error")
  end

  # Real-wiring smoke test: the database is always available during a Rails test
  # run, so this exercises the un-stubbed path end-to-end without being brittle
  # about optional infrastructure (Redis/Sidekiq may legitimately be absent).
  it "reports live database connectivity" do
    get "/api/v1/health"

    expect(response.parsed_body).to include("components")
    expect(response.parsed_body["components"]["database"]).to eq("ok")
    expect(response).to have_http_status(:ok).or have_http_status(:service_unavailable)
  end
end
