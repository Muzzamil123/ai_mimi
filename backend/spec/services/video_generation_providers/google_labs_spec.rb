require "rails_helper"

RSpec.describe VideoGenerationProviders::GoogleLabs do
  subject(:provider) { described_class.new }

  let(:base) { "https://labs.example.com" }
  let(:reference) { { data: "img".b, mime_type: "image/png" } }

  around do |example|
    original = ENV.values_at("GOOGLE_LABS_API_BASE_URL", "GOOGLE_LABS_API_KEY")
    ENV["GOOGLE_LABS_API_BASE_URL"] = base
    ENV["GOOGLE_LABS_API_KEY"] = "k-test"
    example.run
    ENV["GOOGLE_LABS_API_BASE_URL"], ENV["GOOGLE_LABS_API_KEY"] = original
  end

  it "creates a generation and returns the normalized job" do
    stub_request(:post, "#{base}/generations")
      .with(headers: { "Authorization" => "Bearer k-test" })
      .to_return(status: 200, body: { id: "job-42", request_id: "req-7" }.to_json,
                 headers: { "Content-Type" => "application/json" })

    result = provider.create_generation(prompt: "clip", reference_image: reference,
                                        options: { aspect_ratio: "9:16", variation_number: 2, duration_seconds: 15 })

    expect(result.provider_job_id).to eq("job-42")
    expect(result.provider).to eq("google_labs")
    expect(result.estimated_cost).to be > 0
  end

  it "normalizes provider states in fetch_status" do
    stub_request(:get, "#{base}/generations/job-42")
      .to_return(status: 200, body: { status: "running", progress: 30 }.to_json)

    status = provider.fetch_status(job_id: "job-42")
    expect(status).to be_processing
    expect(status.progress).to eq(30)
  end

  it "raises a retryable RateLimited on 429" do
    stub_request(:post, "#{base}/generations").to_return(status: 429, body: "{}")

    expect { provider.create_generation(prompt: "x", reference_image: reference) }
      .to raise_error(VideoGenerationProviders::RateLimited) { |e| expect(e.retryable).to be(true) }
  end

  it "raises NotConfigured without credentials" do
    ENV["GOOGLE_LABS_API_KEY"] = ""
    expect { provider.create_generation(prompt: "x", reference_image: reference) }
      .to raise_error(VideoGenerationProviders::NotConfigured)
  end
end

RSpec.describe VideoGenerationProviders::WebhookVerifier do
  around do |example|
    original = ENV["GOOGLE_LABS_WEBHOOK_SECRET"]
    ENV["GOOGLE_LABS_WEBHOOK_SECRET"] = "shh"
    example.run
    ENV["GOOGLE_LABS_WEBHOOK_SECRET"] = original
  end

  it "accepts a correct HMAC signature and rejects a bad one" do
    payload = '{"job_id":"job-1","status":"completed"}'
    good = OpenSSL::HMAC.hexdigest("SHA256", "shh", payload)

    expect(described_class.valid?(payload: payload, signature: good)).to be(true)
    expect(described_class.valid?(payload: payload, signature: "bad")).to be(false)
    expect(described_class.valid?(payload: payload, signature: nil)).to be(false)
  end

  it "rejects when no secret is configured" do
    ENV["GOOGLE_LABS_WEBHOOK_SECRET"] = ""
    expect(described_class.valid?(payload: "x", signature: "y")).to be(false)
  end
end
