require "rails_helper"

RSpec.describe "Maintenance mode", type: :request do
  before { PlatformSetting.set("maintenance_mode", "true") }

  it "blocks a normal user's write request with 503" do
    user = create(:user)

    post "/api/v1/projects",
         params: { project: { name: "New", default_language: "english", default_tone: "warm" } },
         headers: auth_headers(user)

    expect(response).to have_http_status(:service_unavailable)
    expect(response.parsed_body.dig("error", "code")).to eq("maintenance")
  end

  it "still allows read (GET) requests" do
    user = create(:user)
    get "/api/v1/projects", headers: auth_headers(user)
    expect(response).to have_http_status(:ok)
  end

  it "exempts admins so they can operate the portal" do
    admin = create(:user, :admin)

    post "/api/v1/projects",
         params: { project: { name: "Admin project", default_language: "english", default_tone: "warm" } },
         headers: auth_headers(admin)

    expect(response).to have_http_status(:created)
  end

  it "does not block unauthenticated auth flows (login remains available)" do
    user = create(:user, password: "password123")

    post "/api/v1/auth/login", params: { email: user.email, password: "password123" }

    expect(response).not_to have_http_status(:service_unavailable)
  end
end
