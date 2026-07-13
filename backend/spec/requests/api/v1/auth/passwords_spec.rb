require "rails_helper"

RSpec.describe "Auth passwords", type: :request do
  let!(:user) { create(:user, email: "p@example.com", password: "password123") }

  describe "POST /api/v1/auth/password/forgot" do
    it "returns 202 and enqueues a reset email for a known address" do
      expect do
        post "/api/v1/auth/password/forgot", params: { email: "p@example.com" }, as: :json
      end.to have_enqueued_mail(UserMailer, :password_reset)

      expect(response).to have_http_status(:accepted)
    end

    it "returns 202 without enqueuing for an unknown address (no enumeration)" do
      expect do
        post "/api/v1/auth/password/forgot", params: { email: "nobody@example.com" }, as: :json
      end.not_to have_enqueued_mail(UserMailer, :password_reset)

      expect(response).to have_http_status(:accepted)
    end
  end

  describe "POST /api/v1/auth/password/reset" do
    it "resets the password and revokes existing sessions" do
      old_tokens = Auth::IssueTokens.call(user)
      token = user.generate_token_for(:password_reset)

      post "/api/v1/auth/password/reset", params: { token: token, password: "newpassword123" }, as: :json

      expect(response).to have_http_status(:no_content)
      expect(user.reload.authenticate("newpassword123")).to be_truthy

      post "/api/v1/auth/refresh", params: { refresh_token: old_tokens.refresh_token }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects an invalid token" do
      post "/api/v1/auth/password/reset", params: { token: "bad", password: "newpassword123" }, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
