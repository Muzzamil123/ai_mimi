require "rails_helper"

RSpec.describe "VideoAssets pipeline services" do
  # A completed generation whose fake job id yields a 3:4, 15s fake video.
  def completed_generation(aspect: "3:4", variation: 1)
    video = ready_to_generate_video
    video.update!(status: :generating)
    create(:video_generation, :completed,
           video: video, project: video.project,
           character: video.project.active_character, prompt: video.active_prompt,
           aspect_ratio: aspect, variation_number: variation)
  end

  def asset_for(generation)
    generation.create_video_asset!
  end

  describe VideoAssets::Download do
    it "fetches, stages the bytes, and records checksum/size (pending)" do
      generation = completed_generation
      asset = asset_for(generation)

      described_class.call(asset)

      asset.reload
      expect(asset).to be_validation_pending
      expect(asset.checksum).to be_present
      expect(asset.file_size).to be > 0
      expect(Storage.adapter.read(asset.storage_key)).to start_with("FAKEVID")
    end

    it "dedupes identical bytes from another output of the same video (no second store)" do
      video = ready_to_generate_video
      video.update!(status: :generating)
      generation = create(:video_generation, :completed, video: video, project: video.project,
                                                         character: video.project.active_character,
                                                         prompt: video.active_prompt,
                                                         aspect_ratio: "3:4", variation_number: 1)
      other = create(:video_generation, :completed, video: video, project: video.project,
                                                    character: video.project.active_character,
                                                    prompt: video.active_prompt,
                                                    aspect_ratio: "9:16", variation_number: 2)
      # Force identical provider bytes for both outputs of this video.
      allow_any_instance_of(VideoGenerationProviders::Fake).to receive(:fetch_asset)
        .and_return({ data: "FAKEVID;duration=15;width=720;height=960;same".b, mime_type: "video/mp4" })

      first = asset_for(generation)
      described_class.call(first)
      first.update!(validation_status: :valid, stored_at: Time.current) # simulate ready

      dup = asset_for(other)
      described_class.call(dup)

      expect(dup.reload).to be_duplicate
      expect(dup.duplicate_of_id).to eq(first.id)
      expect(dup.storage_key).to eq(first.storage_key)
      expect(dup).to be_ready
    end
  end

  describe VideoAssets::Validate do
    def staged_asset(aspect: "3:4", header: nil)
      generation = completed_generation(aspect: aspect)
      asset = asset_for(generation)
      VideoAssets::Download.call(asset)
      Storage.adapter.store(key: asset.storage_key, data: header, content_type: "video/mp4") if header
      asset.reload
    end

    it "marks a well-formed output valid and records dimensions" do
      asset = staged_asset

      described_class.call(asset)

      asset.reload
      expect(asset).to be_validation_valid
      expect(asset.width).to eq(720)
      expect(asset.height).to eq(960)
      expect(asset.duration_seconds).to eq(15)
    end

    it "marks an unplayable file invalid" do
      asset = staged_asset(header: "not a video".b)
      described_class.call(asset)
      expect(asset.reload).to be_validation_invalid
    end

    it "marks the wrong duration invalid" do
      asset = staged_asset(header: "FAKEVID;duration=30;width=720;height=960;".b)
      described_class.call(asset)
      expect(asset.reload).to be_validation_invalid
    end

    it "marks the wrong aspect ratio invalid" do
      asset = staged_asset(header: "FAKEVID;duration=15;width=1000;height=1000;".b)
      described_class.call(asset)
      expect(asset.reload).to be_validation_invalid
    end

    it "marks an unsupported file type invalid" do
      asset = staged_asset
      asset.update!(mime_type: "text/plain")
      described_class.call(asset)
      expect(asset.reload).to be_validation_invalid
    end

    it "raises a storage error when the staged file is gone" do
      asset = staged_asset
      Storage.adapter.delete(asset.storage_key)
      expect { described_class.call(asset) }.to raise_error(Storage::Error)
    end

    it "reclaims the staged bytes when the output is invalid" do
      asset = staged_asset(header: "FAKEVID;duration=30;width=720;height=960;".b)
      staging = asset.storage_key

      described_class.call(asset)

      expect(asset.reload).to be_validation_invalid
      expect(Storage.adapter.exist?(staging)).to be(false)
    end
  end

  describe VideoAssets::Store do
    it "moves the file to a permanent key and marks it stored" do
      generation = completed_generation
      asset = asset_for(generation)
      VideoAssets::Download.call(asset)
      staging = asset.reload.storage_key

      described_class.call(asset)

      asset.reload
      expect(asset.stored_at).to be_present
      expect(asset.storage_key).not_to eq(staging)
      expect(Storage.adapter.exist?(staging)).to be(false)
      expect(Storage.adapter.exist?(asset.storage_key)).to be(true)
    end
  end

  describe VideoAssets::BuildArchive do
    it "zips ready assets into a single archive" do
      a = create(:video_asset, :ready)
      Storage.adapter.store(key: a.storage_key, data: "AAAA", content_type: "video/mp4")
      b = create(:video_asset, :ready)
      Storage.adapter.store(key: b.storage_key, data: "BBBB", content_type: "video/mp4")

      data = described_class.call([ a, b ])

      expect(data[0, 2]).to eq("PK") # ZIP local file header
      expect(data.bytesize).to be > 0
    end
  end
end
