require "rails_helper"

RSpec.describe "Video generation cost estimate & budget enforcement", type: :request do
  let(:user) { create(:user) }
  let(:video) { ready_to_generate_video(user: user) }
  let(:provider) { VideoGenerationProviders.default_provider }

  def estimate_path
    "/api/v1/projects/#{video.project_id}/videos/#{video.id}/generations/estimate"
  end

  def create_path
    "/api/v1/projects/#{video.project_id}/videos/#{video.id}/generations"
  end

  before do
    create(:provider_price, provider: provider, service_type: "video_generation", model: "",
                            per_input_token: nil, per_output_token: nil, per_second: "0.05")
  end

  describe "GET .../generations/estimate" do
    it "returns the configured estimate and budget status" do
      get estimate_path, headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["estimate"]).to include("total" => 3.0, "variant_count" => 4, "configured" => true)
      expect(body["budget"]["status"]).to eq("ok")
    end

    it "reports a budget warning/exceed in the estimate" do
      create(:budget_policy, scope_type: "global", monthly_limit: "1.00", action_on_limit: "block")

      get estimate_path, headers: auth_headers(user)

      expect(response.parsed_body["budget"]["blocked"]).to be(true)
      expect(response.parsed_body["budget"]["status"]).to eq("exceeded")
    end
  end

  describe "POST .../generations with a hard budget block" do
    before { create(:budget_policy, :block, scope_type: "global", monthly_limit: "1.00") }

    it "blocks a normal user with 422 budget_exceeded" do
      post create_path, headers: auth_headers(user)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "code")).to eq("budget_exceeded")
      expect(video.reload).to be_prompt_ready # not queued
    end

    it "lets an admin override the block" do
      admin = create(:user, :admin)

      post create_path, params: { override: true }, headers: auth_headers(admin)

      expect(response).to have_http_status(:accepted)
      expect(video.reload).to be_queued
    end
  end
end
