require "rails_helper"

RSpec.describe "Project archive/restore services" do
  let(:user) { create(:user) }

  describe Projects::ArchiveProject do
    it "archives a project and records history" do
      project = create(:project, user: user)
      described_class.call(project, actor: user)

      expect(project.reload).to be_archived
      expect(project.status_changes.last.to_status).to eq("archived")
    end
  end

  describe Projects::RestoreProject do
    it "restores to the status held before archiving" do
      project = create(:project, user: user, status: :ready)
      project.transition_to!(:archived, actor: user)

      described_class.call(project, actor: user)

      expect(project.reload).to be_ready
    end

    it "restores to the most recent pre-archive status across multiple cycles" do
      project = create(:project, user: user, status: :ready)
      project.transition_to!(:archived, actor: user) # archived from "ready"
      described_class.call(project, actor: user)      # -> ready

      project.update!(status: :failed)                # move to a different state
      project.transition_to!(:archived, actor: user)  # archived from "failed"
      described_class.call(project, actor: user)      # must restore to "failed", not "ready"

      expect(project.reload).to be_failed
    end

    it "raises when the project is not archived" do
      project = create(:project, user: user)
      expect { described_class.call(project, actor: user) }
        .to raise_error(Projects::InvalidTransition)
    end
  end
end
