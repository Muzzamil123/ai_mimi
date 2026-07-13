require "rails_helper"

RSpec.describe "POST /api/v1/auth/email/verify", type: :request do
  let(:user) { create(:user) }

  it "verifies the account with a valid token" do
    token = user.generate_token_for(:email_verification)

    post "/api/v1/auth/email/verify", params: { token: token }, as: :json

    expect(response).to have_http_status(:no_content)
    expect(user.reload.email_verified?).to be(true)
  end

  it "rejects an invalid token" do
    post "/api/v1/auth/email/verify", params: { token: "bad" }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end
end
