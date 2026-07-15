require "rails_helper"

# The individual generation-step services, exercised with the default Fake image
# provider, the Local prompt provider, and the in-memory storage adapter.
RSpec.describe "Characters generation pipeline services" do
  let(:project) { create(:project, status: :initializing_character) }
  let(:character) { create(:character, :generating, project: project) }

  describe Characters::GeneratePrompt do
    it "builds and persists a generation prompt" do
      described_class.call(character)

      expect(character.reload.generation_prompt).to be_present
    end
  end

  describe Characters::GenerateImage do
    it "calls the provider, stores the asset, and records provider metadata" do
      character.update!(generation_prompt: "a fox")

      staged = described_class.call(character, character.generation_id)

      expect(Storage.adapter.exist?(staged.storage_key)).to be(true)
      expect(character.reload.provider).to eq("fake")
      expect(character.provider_model).to eq("fake-image-1")
      expect(character.estimated_cost).to eq(0)
    end
  end

  describe Characters::StoreGeneratedImage do
    it "creates a verified image record and awaits approval" do
      png = Base64.decode64(CharacterImageProviders::Fake::PNG_1PX_BASE64)
      key = "characters/#{character.id}/#{character.generation_id}/source.png"
      Storage.adapter.store(key: key, data: png, content_type: "image/png")

      image = described_class.call(character, storage_key: key, mime_type: "image/png", provider_asset_id: "a1")

      expect(image.width).to eq(1)
      expect(image.height).to eq(1)
      expect(image.file_size).to eq(png.bytesize)
      expect(image.checksum).to eq(Digest::SHA256.hexdigest(png))
      expect(character.reload).to be_awaiting_approval
      expect(project.reload).to be_awaiting_character_approval
    end

    it "raises a storage error when the asset is missing" do
      expect { described_class.call(character, storage_key: "missing", mime_type: "image/png") }
        .to raise_error(Storage::Error)
    end
  end

  describe Characters::FailGeneration do
    it "marks the character and project failed for the active generation" do
      described_class.call(character, generation_id: character.generation_id, reason: "boom")

      expect(character.reload).to be_failed
      expect(character.failure_reason).to eq("boom")
      expect(project.reload).to be_failed
    end

    it "is a no-op for a superseded generation_id" do
      described_class.call(character, generation_id: "stale", reason: "boom")

      expect(character.reload).to be_generating
    end
  end
end
