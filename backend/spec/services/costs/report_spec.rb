require "rails_helper"

RSpec.describe Costs::Report, type: :service do
  it "aggregates totals, by-provider, by-service, and averages over the window" do
    project = create(:project)
    video = create(:video, project: project)
    create(:provider_usage, project: project, video: video, provider: "openai",
                            service_type: "text_generation", estimated_cost: "0.50")
    create(:provider_usage, :video_generation, project: project, video: video, estimated_cost: "3.00")
    create(:provider_usage, provider: "openai", service_type: "text_generation",
                            estimated_cost: "0", metadata: { "pricing_source" => "unpriced" })

    report = described_class.call

    expect(report[:totals][:estimated_cost]).to eq(3.5)
    expect(report[:totals][:count]).to eq(3)
    expect(report[:totals][:unpriced_count]).to eq(1)
    expect(report[:by_provider].first[:key]).to eq("google_labs") # highest spend first
    expect(report[:by_service].map { |r| r[:key] }).to include("text_generation", "video_generation")
    expect(report[:averages][:per_video]).to eq(3.0) # one video with video_generation spend
  end

  it "excludes usage outside the window" do
    create(:provider_usage, estimated_cost: "5", occurred_at: 90.days.ago)
    report = described_class.call(from: 30.days.ago, to: Time.current)
    expect(report[:totals][:count]).to eq(0)
  end
end
