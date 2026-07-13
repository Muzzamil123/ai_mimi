require "rails_helper"

RSpec.describe "GET /api/v1/admin/users", type: :request do
  it "lists users for an admin" do
    create_list(:user, 2)
    admin = create(:user, :admin)

    get "/api/v1/admin/users", headers: auth_headers(admin)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.size).to be >= 3
  end

  it "forbids a normal user (403)" do
    user = create(:user)

    get "/api/v1/admin/users", headers: auth_headers(user)

    expect(response).to have_http_status(:forbidden)
    expect(response.parsed_body["error"]["code"]).to eq("forbidden")
  end

  it "requires authentication (401)" do
    get "/api/v1/admin/users"
    expect(response).to have_http_status(:unauthorized)
  end
end
