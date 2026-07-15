require "rails_helper"

# Approve / reject / admin-reset service behaviour and their guards.
RSpec.describe "Characters lifecycle actions" do
  let(:project) { create(:project) }
  let(:owner) { project.user }

  # Drives a character to `awaiting_approval` with its project in sync.
  def character_awaiting_approval
    character = create(:character, project: project)
    character.transition_to!(:generating, actor: owner)
    character.transition_to!(:awaiting_approval, actor: owner)
    character
  end

  describe Characters::ApproveCharacter do
    it "approves, locks, and marks the project ready" do
      character = character_awaiting_approval

      described_class.call(character, actor: owner)

      expect(character.reload).to be_approved
      expect(project.reload).to be_ready
      expect(project.active_character_id).to eq(character.id)
    end

    it "refuses to approve a character that is not awaiting approval" do
      character = create(:character, project: project)

      expect { described_class.call(character, actor: owner) }
        .to raise_error(Characters::InvalidState)
    end
  end

  describe Characters::RejectCharacter do
    it "records feedback and moves the project to character_rejected" do
      character = character_awaiting_approval

      described_class.call(character, feedback: "too scary", actor: owner)

      expect(character.reload).to be_rejected
      expect(character.rejection_feedback).to eq("too scary")
      expect(project.reload).to be_character_rejected
    end
  end

  describe Characters::ResetCharacter do
    let(:admin) { create(:user, :admin) }

    it "resets an approved character when performed by an admin" do
      character = character_awaiting_approval
      Characters::ApproveCharacter.call(character, actor: owner)

      described_class.call(character, actor: admin)

      expect(character.reload).to be_pending
      expect(project.reload.active_character_id).to be_nil
    end

    it "refuses a non-admin actor" do
      character = character_awaiting_approval

      expect { described_class.call(character, actor: owner) }
        .to raise_error(Characters::InvalidState, /administrator/)
    end
  end
end
