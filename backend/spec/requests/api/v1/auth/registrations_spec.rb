require "rails_helper"

RSpec.describe "POST /api/v1/auth/register", type: :request do
  let(:params) { { user: { name: "Ann", email: "ann@example.com", password: "password123" } } }

  it "creates a user, returns tokens, and enqueues a verification email" do
    expect do
      post "/api/v1/auth/register", params: params, as: :json
    end.to change(User, :count).by(1)
      .and have_enqueued_mail(UserMailer, :email_verification)

    expect(response).to have_http_status(:created)
    body = response.parsed_body
    expect(body["user"]["email"]).to eq("ann@example.com")
    expect(body["user"]).not_to have_key("password_digest")
    expect(body["tokens"]["access_token"]).to be_present
    expect(body["tokens"]["refresh_token"]).to be_present
    expect(body["tokens"]["token_type"]).to eq("Bearer")
  end

  it "rejects a duplicate email" do
    create(:user, email: "ann@example.com")
    post "/api/v1/auth/register", params: params, as: :json

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.parsed_body["error"]["code"]).to eq("validation_failed")
  end

  it "rejects a short password" do
    post "/api/v1/auth/register",
         params: { user: { name: "A", email: "b@example.com", password: "x" } }, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "rejects missing user params" do
    post "/api/v1/auth/register", params: {}, as: :json
    expect(response).to have_http_status(:unprocessable_entity)
  end
end
