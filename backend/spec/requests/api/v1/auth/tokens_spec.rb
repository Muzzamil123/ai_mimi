require "rails_helper"

RSpec.describe "POST /api/v1/auth/refresh", type: :request do
  let(:user) { create(:user) }

  it "rotates tokens for a valid refresh token" do
    tokens = Auth::IssueTokens.call(user)

    post "/api/v1/auth/refresh", params: { refresh_token: tokens.refresh_token }, as: :json

    expect(response).to have_http_status(:ok)
    new_refresh = response.parsed_body["tokens"]["refresh_token"]
    expect(new_refresh).to be_present
    expect(new_refresh).not_to eq(tokens.refresh_token)
  end

  it "rejects an invalid refresh token" do
    post "/api/v1/auth/refresh", params: { refresh_token: "nope" }, as: :json
    expect(response).to have_http_status(:unauthorized)
  end
end
