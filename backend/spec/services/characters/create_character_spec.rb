require "rails_helper"

RSpec.describe Characters::CreateCharacter do
  let(:project) { create(:project) }

  it "creates a pending character for a draft project" do
    character = described_class.call(project, { name: "Rusty", description: "a fox" }, actor: project.user)

    expect(character).to be_persisted
    expect(character).to be_pending
    expect(character.project).to eq(project)
    expect(project.reload).to be_draft
  end

  it "refuses a second character for the same project" do
    create(:character, project: project)

    expect { described_class.call(project, { name: "Dup" }) }
      .to raise_error(Characters::InvalidState, /already has a character/)
  end

  it "refuses to set up a character once the project has left draft" do
    project.update!(status: :ready)

    expect { described_class.call(project, { name: "Late" }) }
      .to raise_error(Characters::InvalidState, /draft/)
  end
end
