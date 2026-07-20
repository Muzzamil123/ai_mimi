require "rails_helper"

RSpec.describe Prompt do
  describe "validations" do
    it "is valid with the factory" do
      expect(build(:prompt)).to be_valid
    end

    it "requires content once draft/approved" do
      expect(build(:prompt, status: :draft, content: nil)).not_to be_valid
      expect(build(:prompt, :generating, content: nil)).to be_valid
    end

    it "enforces unique version per video" do
      prompt = create(:prompt, version: 1)
      dup = build(:prompt, video: prompt.video, version: 1)
      expect(dup).not_to be_valid
      expect(dup.errors[:version]).to be_present
    end

    it "allows the same version number on different videos" do
      a = create(:prompt, version: 1)
      b = build(:prompt, version: 1)
      expect(b).to be_valid
      expect(b.video_id).not_to eq(a.video_id)
    end
  end

  describe "#transition_to!" do
    it "allows generating -> draft -> approved" do
      prompt = create(:prompt, :generating, content: nil)
      prompt.update!(content: "x")
      prompt.transition_to!(:draft)
      expect(prompt).to be_draft
      prompt.transition_to!(:approved)
      expect(prompt).to be_approved
    end

    it "rejects a disallowed transition" do
      prompt = create(:prompt, :approved)
      expect { prompt.transition_to!(:draft) }
        .to raise_error(Prompts::InvalidTransition, /Cannot transition/)
    end
  end

  describe "scopes" do
    it "live excludes superseded and failed" do
      video = create(:video, :with_idea)
      draft = create(:prompt, video: video, version: 1, status: :draft)
      create(:prompt, :superseded, video: video, version: 2)
      create(:prompt, :failed, video: video, version: 3)

      expect(video.prompts.live).to contain_exactly(draft)
    end
  end

  describe "created_by (polymorphic)" do
    it "attributes a version to its author" do
      user = create(:user)
      prompt = create(:prompt, created_by: user)
      expect(prompt.created_by).to eq(user)
      expect(prompt.created_by_type).to eq("User")
    end
  end
end
