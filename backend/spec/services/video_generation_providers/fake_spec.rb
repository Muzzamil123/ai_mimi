require "rails_helper"

RSpec.describe VideoGenerationProviders::Fake do
  subject(:provider) { described_class.new }

  let(:reference) { { data: "img".b, mime_type: "image/png" } }

  it "accepts a job and reports it completed" do
    result = provider.create_generation(prompt: "a clip", reference_image: reference,
                                        options: { aspect_ratio: "3:4", variation_number: 1 })
    expect(result.provider).to eq("fake")
    expect(result.provider_job_id).to be_present

    status = provider.fetch_status(job_id: result.provider_job_id)
    expect(status).to be_completed
  end

  it "rejects a missing prompt or reference image" do
    expect { provider.create_generation(prompt: "", reference_image: reference) }
      .to raise_error(VideoGenerationProviders::Error, /prompt/)
    expect { provider.create_generation(prompt: "x", reference_image: nil) }
      .to raise_error(VideoGenerationProviders::Error, /reference/)
  end
end

RSpec.describe VideoGenerationProviders do
  describe ".build" do
    it "builds fake and google_labs, raising on unknown" do
      expect(described_class.build(name: "fake")).to be_a(VideoGenerationProviders::Fake)
      expect(described_class.build(name: "google_labs")).to be_a(VideoGenerationProviders::GoogleLabs)
      expect { described_class.build(name: "nope") }.to raise_error(VideoGenerationProviders::Error)
    end
  end
end
