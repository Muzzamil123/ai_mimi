require "rails_helper"
require "base64"

RSpec.describe "Character approvals API", type: :request do
  include ActiveJob::TestHelper

  let(:user) { create(:user, email: "owner@example.com") }
  let(:project) { create(:project, user: user) }

  # A character synced to `awaiting_approval` (project follows) with a stored
  # preview image, matching the real generation pipeline's end state.
  let(:character) do
    c = create(:character, project: project)
    c.transition_to!(:generating)
    c.transition_to!(:awaiting_approval)
    png = Base64.decode64(CharacterImageProviders::Fake::PNG_1PX_BASE64)
    Storage.adapter.store(key: "approvals/img.png", data: png, content_type: "image/png")
    create(:character_image, character: c, storage_key: "approvals/img.png", mime_type: "image/png")
    c
  end

  # Mints a real approval request and returns [request, raw_token].
  def mint_token
    result = Approvals::CreateApprovalRequest.call(character)
    [ result.approval_request, result.raw_token ]
  end

  describe "GET /api/v1/approvals/character/:token" do
    it "returns the resolved state without requiring authentication" do
      _request, token = mint_token

      get "/api/v1/approvals/character/#{token}"

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["status"]).to eq("pending")
      expect(body["actionable"]).to be(true)
      expect(body.dig("project", "name")).to eq(project.name)
      expect(body.dig("character", "name")).to eq(character.name)
      expect(body.dig("character", "has_image")).to be(true)
    end

    it "does not leak the owner email or token digest" do
      _request, token = mint_token
      get "/api/v1/approvals/character/#{token}"
      expect(response.body).not_to include("owner@example.com")
      expect(response.body).not_to include("token_digest")
    end

    it "404s for an unknown/tampered token" do
      mint_token
      get "/api/v1/approvals/character/tampered-token"

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body.dig("error", "code")).to eq("invalid_token")
    end

    it "reports an expired link as expired (200), not actionable" do
      request, token = mint_token
      request.update!(expires_at: 1.hour.ago)

      get "/api/v1/approvals/character/#{token}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("expired")
      expect(response.parsed_body["actionable"]).to be(false)
    end
  end

  describe "POST /api/v1/approvals/character/:token/approve" do
    it "approves the character and readies the project" do
      request, token = mint_token

      post "/api/v1/approvals/character/#{token}/approve"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("approved")
      expect(request.reload).to be_approved
      expect(character.reload).to be_approved
      expect(project.reload).to be_ready
    end

    it "410s on an expired link" do
      request, token = mint_token
      request.update!(expires_at: 1.hour.ago)

      post "/api/v1/approvals/character/#{token}/approve"

      expect(response).to have_http_status(:gone)
      expect(response.parsed_body.dig("error", "code")).to eq("link_expired")
    end

    it "409s when the single-use link is reused" do
      _request, token = mint_token

      post "/api/v1/approvals/character/#{token}/approve"
      expect(response).to have_http_status(:ok)

      post "/api/v1/approvals/character/#{token}/approve"
      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body.dig("error", "code")).to eq("already_processed")
    end
  end

  describe "POST /api/v1/approvals/character/:token/reject" do
    it "rejects the character with feedback and moves the project to character_rejected" do
      request, token = mint_token

      post "/api/v1/approvals/character/#{token}/reject", params: { feedback: "make it younger" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("rejected")
      expect(request.reload.feedback).to eq("make it younger")
      expect(character.reload).to be_rejected
      expect(character.rejection_feedback).to eq("make it younger")
      expect(project.reload.status).to eq("character_rejected")
    end
  end

  describe "GET /api/v1/approvals/character/:token/image" do
    it "streams the character preview image via the token" do
      _request, token = mint_token

      get "/api/v1/approvals/character/#{token}/image"

      expect(response).to have_http_status(:ok)
      expect(response.body).to be_present
    end

    it "404s for a tampered token" do
      get "/api/v1/approvals/character/tampered/image"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "end-to-end: email recipient is the owner's account email" do
    it "sends the approval email to the current owner and the link works" do
      perform_enqueued_jobs do
        SendCharacterApprovalEmailJob.perform_later(character.id, character.generation_id)
      end

      mail = ActionMailer::Base.deliveries.last
      expect(mail.to).to eq([ "owner@example.com" ])

      # The emailed token must resolve to an actionable request.
      token = character.approval_requests.pending.sole
      expect(token).to be_actionable
    end
  end
end
