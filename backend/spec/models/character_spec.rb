require "rails_helper"

RSpec.describe Character, type: :model do
  let(:project) { create(:project) }

  describe "validations and associations" do
    it "is valid with a name and project" do
      expect(build(:character, project: project)).to be_valid
    end

    it "requires a name" do
      character = build(:character, project: project, name: nil)
      expect(character).not_to be_valid
      expect(character.errors[:name]).to be_present
    end

    it "enforces one character per project (model validation)" do
      create(:character, project: project)
      duplicate = build(:character, project: project)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:project_id]).to include("already has a character")
    end

    it "enforces one character per project (unique index)" do
      create(:character, project: project)
      expect do
        described_class.new(name: "Dupe", project_id: project.id).save!(validate: false)
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "#transition_to!" do
    it "allows a permitted transition and keeps the project status in sync" do
      character = create(:character, project: project)

      character.transition_to!(:generating, actor: project.user)

      expect(character.reload).to be_generating
      expect(project.reload).to be_initializing_character
      expect(project.status_changes.last.to_status).to eq("initializing_character")
    end

    it "rejects a disallowed transition without side effects" do
      character = create(:character, project: project)

      expect { character.transition_to!(:approved) }
        .to raise_error(Characters::InvalidTransition)
      expect(character.reload).to be_pending
    end

    it "locks the character and sets it active on approval" do
      character = create(:character, project: project)
      character.transition_to!(:generating)
      character.transition_to!(:awaiting_approval)

      character.transition_to!(:approved, actor: project.user)

      expect(character.reload).to be_approved
      expect(character).to be_locked
      expect(character.approved_at).to be_present
      expect(character.locked_at).to be_present
      expect(project.reload).to be_ready
      expect(project.active_character_id).to eq(character.id)
    end

    it "records rejection metadata and moves the project to character_rejected" do
      character = create(:character, project: project)
      character.transition_to!(:generating)
      character.transition_to!(:awaiting_approval)

      character.transition_to!(:rejected, actor: project.user)

      expect(character.reload).to be_rejected
      expect(character.rejected_at).to be_present
      expect(project.reload).to be_character_rejected
    end
  end

  describe "#reset_by_admin!" do
    let(:admin) { create(:user, :admin) }

    it "returns an approved character to pending, clears artifacts, and detaches it" do
      character = create(:character, project: project)
      character.transition_to!(:generating)
      character.transition_to!(:awaiting_approval)
      character.transition_to!(:approved, actor: project.user)
      create(:character_image, character: character)

      character.reset_by_admin!(actor: admin)

      expect(character.reload).to be_pending
      expect(character.approved_at).to be_nil
      expect(character.locked_at).to be_nil
      expect(character.images).to be_empty
      expect(project.reload.active_character_id).to be_nil
      expect(project).to be_draft
    end
  end

  describe "#latest_image" do
    it "returns the most recently created image" do
      character = create(:character, project: project)
      create(:character_image, character: character, storage_key: "a")
      newest = create(:character_image, character: character, storage_key: "b")

      expect(character.latest_image).to eq(newest)
    end
  end
end
