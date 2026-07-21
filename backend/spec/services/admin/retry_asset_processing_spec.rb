require "rails_helper"

RSpec.describe Admin::RetryAssetProcessing, type: :service do
  include ActiveJob::TestHelper

  let(:admin) { create(:user, :admin) }

  it "resets a failed asset and re-enqueues the download pipeline" do
    generation = create(:video_generation, :completed)
    asset = create(:video_asset, :ready, video_generation: generation)
    asset.update!(validation_status: :failed, stored_at: Time.current)

    expect {
      described_class.call(generation, actor: admin)
    }.to have_enqueued_job(DownloadGeneratedVideoJob).with(generation.id)

    asset.reload
    expect(asset).to be_validation_pending
    expect(asset.stored_at).to be_nil
  end

  it "enqueues even when no asset exists yet" do
    generation = create(:video_generation, :completed)

    expect {
      described_class.call(generation, actor: admin)
    }.to have_enqueued_job(DownloadGeneratedVideoJob).with(generation.id)
  end

  it "refuses when the generation is not completed" do
    generation = create(:video_generation, :failed)
    expect { described_class.call(generation, actor: admin) }
      .to raise_error(Admin::InvalidOperation)
  end
end
