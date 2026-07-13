require "rails_helper"

RSpec.describe "Current user (/api/v1/me)", type: :request do
  let(:user) { create(:user, name: "Old Name", password: "password123") }

  describe "GET /api/v1/me" do
    it "returns the authenticated user" do
      get "/api/v1/me", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["email"]).to eq(user.email)
      expect(response.parsed_body).not_to have_key("password_digest")
    end

    it "returns 401 without a token" do
      get "/api/v1/me"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with a garbage token" do
      get "/api/v1/me", headers: { "Authorization" => "Bearer not-a-jwt" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "PATCH /api/v1/me" do
    it "updates the name" do
      patch "/api/v1/me", params: { user: { name: "New Name" } }, headers: auth_headers(user), as: :json

      expect(response).to have_http_status(:ok)
      expect(user.reload.name).to eq("New Name")
    end

    it "changes the password when the current password is correct" do
      patch "/api/v1/me",
            params: { user: { password: "brandnew123", current_password: "password123" } },
            headers: auth_headers(user), as: :json

      expect(response).to have_http_status(:ok)
      expect(user.reload.authenticate("brandnew123")).to be_truthy
    end

    it "rejects a password change with the wrong current password" do
      patch "/api/v1/me",
            params: { user: { password: "brandnew123", current_password: "wrong" } },
            headers: auth_headers(user), as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(user.reload.authenticate("brandnew123")).to be_falsey
    end
  end

  describe "DELETE /api/v1/me" do
    it "soft-deletes the account and revokes sessions" do
      user.refresh_tokens.create!(token_digest: "keep", expires_at: 1.day.from_now)

      delete "/api/v1/me", headers: auth_headers(user)

      expect(response).to have_http_status(:no_content)
      expect(user.reload.status).to eq("deleted")
      expect(user.refresh_tokens.active).to be_empty
    end
  end
end
