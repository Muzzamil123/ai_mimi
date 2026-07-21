require "rails_helper"

RSpec.describe "Admin Usage API", type: :request do
  let(:admin) { create(:user, :admin) }

  it_behaves_like "an admin-only endpoint", :get, "/api/v1/admin/usage"

  describe "GET /api/v1/admin/usage" do
    it "summarizes provider usage and cost from recorded calls" do
      create(:prompt, :approved) # openai, tokens + cost
      create(:video_generation, :completed, estimated_cost: 0.5, provider: "fake")

      get "/api/v1/admin/usage", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["prompt_generation"]["total_count"]).to be >= 1
      openai = body["prompt_generation"]["providers"].find { |p| p["provider"] == "openai" }
      expect(openai).to include("input_tokens", "output_tokens")
      expect(openai["input_tokens"]).to be >= 120
      expect(body["video_generation"]["total_estimated_cost"]).to eq(0.5)
    end
  end
end
