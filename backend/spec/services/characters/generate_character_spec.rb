require "rails_helper"

RSpec.describe Characters::GenerateCharacter do
  include ActiveJob::TestHelper

  let(:project) { create(:project) }

  it "starts generation, syncs the project, and enqueues the prompt job" do
    character = create(:character, project: project)

    expect { described_class.call(character, actor: project.user) }
      .to have_enqueued_job(GenerateCharacterPromptJob).with(character.id, kind_of(String))

    expect(character.reload).to be_generating
    expect(character.generation_id).to be_present
    expect(project.reload).to be_initializing_character
  end

  it "rotates the generation_id on regeneration so stale jobs are superseded" do
    character = create(:character, :rejected, project: project, generation_id: SecureRandom.uuid)
    project.update!(status: :character_rejected)
    original = character.generation_id

    described_class.call(character, actor: project.user)

    expect(character.reload.generation_id).not_to eq(original)
    expect(character).to be_generating
  end

  it "refuses to regenerate an approved (locked) character" do
    character = create(:character, :approved, project: project)

    expect { described_class.call(character) }
      .to raise_error(Characters::InvalidState, /locked/)
  end

  it "refuses to start when generation is already in progress" do
    character = create(:character, :generating, project: project)

    expect { described_class.call(character) }
      .to raise_error(Characters::InvalidState, /in progress/)
  end
end
