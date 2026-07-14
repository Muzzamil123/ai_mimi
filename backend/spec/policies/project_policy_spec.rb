require "rails_helper"

RSpec.describe ProjectPolicy do
  let(:owner) { create(:user) }
  let(:other) { create(:user) }
  let(:admin) { create(:user, :admin) }
  let(:project) { create(:project, user: owner) }

  it "permits the owner" do
    expect(described_class.new(owner, project).show?).to be(true)
  end

  it "permits an admin" do
    expect(described_class.new(admin, project).show?).to be(true)
  end

  it "denies an unrelated user" do
    expect(described_class.new(other, project).show?).to be(false)
    expect(described_class.new(other, project).update?).to be(false)
  end

  describe "Scope" do
    it "returns only the user's own projects" do
      mine = create(:project, user: owner)
      create(:project, user: other)
      expect(ProjectPolicy::Scope.new(owner, Project).resolve).to contain_exactly(project, mine)
    end

    it "returns all projects for an admin" do
      create(:project, user: other)
      expect(ProjectPolicy::Scope.new(admin, Project).resolve.count).to eq(Project.count)
    end
  end
end
