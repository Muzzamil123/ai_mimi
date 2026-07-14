require "rails_helper"

RSpec.describe "Rate limiting (Rack::Attack)", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    Rack::Attack.enabled = true
    Rack::Attack.cache.store.clear
    # Freeze time so every request falls in the same throttle window (otherwise
    # requests can straddle a period boundary and reset the counter).
    freeze_time { example.run }
  ensure
    Rack::Attack.enabled = false
    Rack::Attack.cache.store.clear
  end

  it "throttles excessive login attempts from a single IP" do
    11.times do
      post "/api/v1/auth/login", params: { email: "x@example.com", password: "wrong" }, as: :json
    end

    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body["error"]["code"]).to eq("rate_limited")
  end

  it "throttles excessive password-reset requests" do
    6.times do
      post "/api/v1/auth/password/forgot", params: { email: "x@example.com" }, as: :json
    end

    expect(response).to have_http_status(:too_many_requests)
  end
end
