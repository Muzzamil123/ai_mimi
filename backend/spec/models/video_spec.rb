require "rails_helper"

RSpec.describe Video do
  describe "validations" do
    it "is valid with the factory" do
      expect(build(:video)).to be_valid
    end

    it "requires a title" do
      video = build(:video, title: nil)
      expect(video).not_to be_valid
      expect(video.errors[:title]).to be_present
    end

    it "rejects an unsupported language" do
      video = build(:video, language: "klingon")
      expect(video).not_to be_valid
      expect(video.errors[:language]).to be_present
    end

    it "accepts every supported language" do
      Project::SUPPORTED_LANGUAGES.each do |language|
        expect(build(:video, language: language)).to be_valid, "expected #{language} to be valid"
      end
    end

    describe "duration enforcement (Phase 1 = 15s only)" do
      it "accepts 15 seconds" do
        expect(build(:video, duration_seconds: 15)).to be_valid
      end

      it "rejects any non-15 duration by default" do
        [ 10, 30, 60, 300 ].each do |seconds|
          video = build(:video, duration_seconds: seconds)
          expect(video).not_to be_valid, "expected #{seconds}s to be invalid"
          expect(video.errors[:duration_seconds]).to be_present
        end
      end

      it "defaults to 15 seconds when unspecified" do
        video = build(:video, duration_seconds: nil)
        expect(video).to be_valid
        expect(video.duration_seconds).to eq(15)
      end

      it "allows 60–300 seconds when long-form is enabled (future support)" do
        allow(described_class).to receive(:long_form_enabled?).and_return(true)
        expect(build(:video, duration_seconds: 120)).to be_valid
        expect(build(:video, duration_seconds: 15)).not_to be_valid
        expect(build(:video, duration_seconds: 400)).not_to be_valid
      end

      it "defaults to a valid duration under the active policy when long-form is enabled" do
        allow(described_class).to receive(:long_form_enabled?).and_return(true)
        video = build(:video, duration_seconds: nil)
        expect(video).to be_valid
        expect(video.duration_seconds).to eq(60)
      end
    end
  end

  describe "defaults inherited from the project" do
    it "inherits language and tone from the project when unspecified" do
      project = create(:project, :ready, default_language: "urdu", default_tone: "playful")
      video = described_class.create!(project: project, title: "Intro")

      expect(video.language).to eq("urdu")
      expect(video.tone).to eq("playful")
    end
  end

  describe "#idea_present?" do
    it "is true when a typed idea exists" do
      expect(build(:video, idea_text: "hi", transcript: nil).idea_present?).to be(true)
    end

    it "is true when a transcript exists" do
      expect(build(:video, idea_text: nil, transcript: "spoken").idea_present?).to be(true)
    end

    it "is false when neither exists" do
      expect(build(:video, idea_text: nil, transcript: nil).idea_present?).to be(false)
    end
  end

  describe "#transition_to!" do
    it "records status history" do
      video = create(:video)
      video.transition_to!(:idea_ready, reason: "idea provided")

      expect(video.reload).to be_idea_ready
      change = video.status_changes.last
      expect(change.from_status).to eq("draft")
      expect(change.to_status).to eq("idea_ready")
      expect(change.reason).to eq("idea provided")
    end

    it "raises on a disallowed transition" do
      video = create(:video)
      expect { video.transition_to!(:completed) }
        .to raise_error(Videos::InvalidTransition, /Cannot transition/)
    end

    it "does not change the owning project's status" do
      project = create(:project, :ready)
      video = create(:video, project: project)

      video.transition_to!(:idea_ready)

      expect(project.reload).to be_ready
    end
  end

  describe ".search" do
    it "matches on title and idea text, case-insensitively" do
      project = create(:project, :ready)
      a = create(:video, project: project, title: "Launch teaser")
      b = create(:video, project: project, title: "Other", idea_text: "a LAUNCH idea")
      create(:video, project: project, title: "Unrelated")

      expect(described_class.search("launch")).to contain_exactly(a, b)
    end
  end
end
