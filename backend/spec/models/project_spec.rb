require "rails_helper"

RSpec.describe Project, type: :model do
  it "is valid with default attributes" do
    expect(build(:project)).to be_valid
  end

  describe "validations" do
    it "requires a name" do
      expect(build(:project, name: nil)).not_to be_valid
    end

    it "rejects an unsupported language" do
      expect(build(:project, default_language: "klingon")).not_to be_valid
    end

    it "rejects unsupported target platforms" do
      project = build(:project, target_platforms: %w[instagram_reels myspace])
      expect(project).not_to be_valid
      expect(project.errors[:target_platforms].join).to match(/myspace/)
    end

    it "prevents changing the owner after creation" do
      project = create(:project)
      project.user = create(:user)
      expect(project).not_to be_valid
      expect(project.errors[:user_id]).to be_present
    end
  end

  describe "slug generation" do
    it "derives a slug from the name" do
      expect(create(:project, name: "My Cool Project").slug).to eq("my-cool-project")
    end

    it "disambiguates duplicate slugs within a user" do
      user = create(:user)
      first = create(:project, user: user, name: "Same Name")
      second = create(:project, user: user, name: "Same Name")
      expect(first.slug).to eq("same-name")
      expect(second.slug).to eq("same-name-2")
    end

    it "allows the same slug across different users" do
      create(:project, user: create(:user), name: "Shared")
      expect(build(:project, user: create(:user), name: "Shared")).to be_valid
    end
  end

  describe "#transition_to!" do
    it "records history and archives on a valid transition" do
      project = create(:project) # draft
      expect { project.transition_to!(:archived, actor: project.user) }
        .to change { project.status_changes.count }.by(1)
      expect(project.reload).to be_archived
      expect(project.archived_at).to be_present
    end

    it "raises on a disallowed transition" do
      project = create(:project) # draft
      expect { project.transition_to!(:ready) }.to raise_error(Projects::InvalidTransition)
    end

    it "clears archived_at when leaving the archived state" do
      project = create(:project, :archived)
      project.transition_to!(:draft)
      expect(project.reload.archived_at).to be_nil
    end
  end

  describe "scopes" do
    it ".not_archived excludes archived projects" do
      live = create(:project)
      create(:project, :archived)
      expect(Project.not_archived).to contain_exactly(live)
    end

    it ".search matches on name case-insensitively" do
      match = create(:project, name: "Baby Shark Video")
      create(:project, name: "Something Else")
      expect(Project.search("shark")).to contain_exactly(match)
    end
  end
end
