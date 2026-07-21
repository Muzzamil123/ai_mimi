require "rails_helper"

# Phase 14 release validation: the full Phase-1 workflow driven end-to-end
# through the public API with the deterministic fake providers — the automated
# proxy for "a real user can complete the full workflow". Exercises register →
# project → Gemini character generation + approval → video → OpenAI prompt →
# Google-Labs four-output generation → asset download/validation/storage →
# completion email, plus the Phase-12 usage ledger.
RSpec.describe "End-to-end Phase 1 acceptance", type: :request do
  include ActiveJob::TestHelper

  def auth(token)
    { "Authorization" => "Bearer #{token}" }
  end

  it "carries a user through the entire generation workflow" do
    # 1. Register.
    post "/api/v1/auth/register",
         params: { user: { name: "Ada", email: "ada@example.com", password: "password123" } }, as: :json
    expect(response).to have_http_status(:created)
    token = response.parsed_body.dig("tokens", "access_token")
    expect(token).to be_present

    # 2. Create a project.
    post "/api/v1/projects",
         params: { project: { name: "Mascot Reels", default_language: "english", default_tone: "warm" } },
         headers: auth(token)
    expect(response).to have_http_status(:created)
    project_id = response.parsed_body["id"]

    # 3. Set up + generate the one project character (async pipeline, fakes).
    post "/api/v1/projects/#{project_id}/character",
         params: { character: { name: "Rusty", description: "a cheerful fox", attributes: { species: "fox" } } },
         headers: auth(token)
    expect(response).to have_http_status(:created)

    perform_enqueued_jobs do
      post "/api/v1/projects/#{project_id}/character/generate", headers: auth(token)
    end
    expect(response).to have_http_status(:accepted)

    # 4. Approve the character → project becomes ready.
    post "/api/v1/projects/#{project_id}/character/approve", headers: auth(token)
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["status"]).to eq("approved")

    # 5. Create a video, then provide a typed idea (advances it to idea_ready).
    post "/api/v1/projects/#{project_id}/videos",
         params: { video: { title: "Launch teaser" } }, headers: auth(token)
    expect(response).to have_http_status(:created)
    video_id = response.parsed_body["id"]

    patch "/api/v1/projects/#{project_id}/videos/#{video_id}",
          params: { video: { idea_text: "Rusty waves hello and invites new followers." } },
          headers: auth(token)
    expect(response).to have_http_status(:ok)

    # 6. Generate a prompt (async) and approve the latest version.
    perform_enqueued_jobs do
      post "/api/v1/projects/#{project_id}/videos/#{video_id}/prompts/generate", headers: auth(token)
    end
    get "/api/v1/projects/#{project_id}/videos/#{video_id}/prompts", headers: auth(token)
    expect(response).to have_http_status(:ok), "prompts GET: #{response.status} #{response.body}"
    prompt_id = response.parsed_body["prompts"].max_by { |p| p["version"] }["id"]

    post "/api/v1/projects/#{project_id}/videos/#{video_id}/prompts/#{prompt_id}/approve", headers: auth(token)
    expect(response).to have_http_status(:ok)

    # 7. Generate the four outputs (async: submit → poll → download → validate →
    #    store → finalize → completion email).
    perform_enqueued_jobs do
      post "/api/v1/projects/#{project_id}/videos/#{video_id}/generations", headers: auth(token)
    end

    # 8. Four stored, ready outputs and a completed video.
    video = Video.find(video_id)
    expect(video.status).to eq("completed")
    assets = VideoAsset.joins(:video_generation).where(video_generations: { video_id: video_id })
    expect(assets.count).to eq(4)
    expect(assets.all?(&:ready?)).to be(true)

    # 9. A completion email was recorded to the owner's account address.
    completion = EmailDelivery.find_by(user_id: video.project.user_id, email_type: "video_generation_completed")
    expect(completion).to be_present
    expect(completion.recipient).to eq("ada@example.com")

    # 10. Provider usage was ledgered across the billable steps.
    expect(ProviderUsage.where(service_type: "video_generation").count).to eq(4)
    expect(ProviderUsage.where(service_type: "text_generation")).to exist
    expect(ProviderUsage.where(service_type: "character_image")).to exist
  end
end
