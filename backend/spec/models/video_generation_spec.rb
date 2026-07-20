require "rails_helper"

RSpec.describe VideoGeneration do
  it "is valid with the factory" do
    expect(build(:video_generation)).to be_valid
  end

  describe "validations" do
    it "rejects an unsupported aspect ratio" do
      expect(build(:video_generation, aspect_ratio: "16:9")).not_to be_valid
    end

    it "rejects an unsupported variation number" do
      expect(build(:video_generation, variation_number: 3)).not_to be_valid
    end

    it "requires a 15-second duration (Phase 1)" do
      expect(build(:video_generation, duration_seconds: 30)).not_to be_valid
    end

    it "enforces a unique idempotency_key" do
      existing = create(:video_generation)
      dup = build(:video_generation, idempotency_key: existing.idempotency_key)
      expect(dup).not_to be_valid
    end
  end

  describe "#transition_to!" do
    it "stamps started_at on processing and completed_at + 100% on completed" do
      gen = create(:video_generation, provider_job_id: "j")
      gen.transition_to!(:processing)
      expect(gen.started_at).to be_present

      gen.transition_to!(:completed)
      expect(gen).to be_completed
      expect(gen.completed_at).to be_present
      expect(gen.progress).to eq(100)
    end

    it "records error details on failure" do
      gen = create(:video_generation, :processing)
      gen.transition_to!(:failed, error_code: "boom", error_message: "kaboom")
      expect(gen.error_code).to eq("boom")
      expect(gen.error_message).to eq("kaboom")
    end

    it "rejects a disallowed transition" do
      gen = create(:video_generation, :completed)
      expect { gen.transition_to!(:processing) }
        .to raise_error(VideoGenerations::InvalidTransition)
    end

    it "clears both error fields symmetrically on a retry back to pending" do
      gen = create(:video_generation, :failed, error_code: "boom", error_message: "kaboom")
      gen.transition_to!(:pending, error_code: nil, error_message: nil)
      expect(gen.reload.error_code).to be_nil
      expect(gen.error_message).to be_nil
    end
  end

  describe "the variant matrix" do
    it "defines exactly four distinct variants" do
      expect(VideoGenerations.variant_matrix.size).to eq(4)
      expect(VideoGenerations.variant_matrix.uniq.size).to eq(4)
    end
  end
end
