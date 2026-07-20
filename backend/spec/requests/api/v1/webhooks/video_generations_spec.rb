require "rails_helper"
require "openssl"

RSpec.describe "Video Generation Webhook", type: :request do
  include ActiveJob::TestHelper

  let(:secret) { "shh-secret" }

  around do |example|
    original = ENV["GOOGLE_LABS_WEBHOOK_SECRET"]
    ENV["GOOGLE_LABS_WEBHOOK_SECRET"] = secret
    example.run
    ENV["GOOGLE_LABS_WEBHOOK_SECRET"] = original
  end

  def sign(body)
    OpenSSL::HMAC.hexdigest("SHA256", secret, body)
  end

  let(:path) { "/api/v1/webhooks/video_generations" }

  it "rejects a request with a bad signature" do
    body = { job_id: "job-1", status: "completed" }.to_json

    post path, params: body, headers: { "CONTENT_TYPE" => "application/json", "X-Signature" => "wrong" }

    expect(response).to have_http_status(:unauthorized)
    expect(response.parsed_body.dig("error", "code")).to eq("invalid_signature")
  end

  it "accepts a correctly signed webhook and enqueues processing" do
    body = { job_id: "job-1", status: "completed" }.to_json

    expect {
      post path, params: body, headers: { "CONTENT_TYPE" => "application/json", "X-Signature" => sign(body) }
    }.to have_enqueued_job(HandleVideoGenerationWebhookJob)

    expect(response).to have_http_status(:accepted)
  end

  it "drives the matching variant to completion end-to-end" do
    video = ready_to_generate_video
    video.update!(status: :generating)
    record = create(:video_generation, :processing,
                    video: video, project: video.project,
                    character: video.project.active_character, prompt: video.active_prompt,
                    provider_job_id: "job-xyz")
    body = { job_id: "job-xyz", status: "completed" }.to_json

    perform_enqueued_jobs do
      post path, params: body, headers: { "CONTENT_TYPE" => "application/json", "X-Signature" => sign(body) }
    end

    expect(record.reload).to be_completed
  end
end
