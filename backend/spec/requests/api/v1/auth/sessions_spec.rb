require "rails_helper"

RSpec.describe "Auth sessions", type: :request do
  let!(:user) { create(:user, email: "s@example.com", password: "password123") }

  describe "POST /api/v1/auth/login" do
    it "returns tokens for valid credentials" do
      post "/api/v1/auth/login", params: { email: "s@example.com", password: "password123" }, as: :json

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["tokens"]["access_token"]).to be_present
      expect(response.parsed_body["user"]["email"]).to eq("s@example.com")
    end

    it "returns 401 for invalid credentials" do
      post "/api/v1/auth/login", params: { email: "s@example.com", password: "wrong" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]["code"]).to eq("unauthorized")
    end

    it "returns 401 for a suspended account" do
      user.update!(status: :suspended)
      post "/api/v1/auth/login", params: { email: "s@example.com", password: "password123" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/auth/logout" do
    it "revokes the refresh token so it can no longer be refreshed" do
      tokens = Auth::IssueTokens.call(user)

      post "/api/v1/auth/logout", params: { refresh_token: tokens.refresh_token }, as: :json
      expect(response).to have_http_status(:no_content)

      post "/api/v1/auth/refresh", params: { refresh_token: tokens.refresh_token }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "is a no-op (204) for an unknown token" do
      post "/api/v1/auth/logout", params: { refresh_token: "unknown" }, as: :json
      expect(response).to have_http_status(:no_content)
    end
  end
end
