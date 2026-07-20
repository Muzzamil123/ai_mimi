require "rails_helper"

RSpec.describe Prompts::BuildContext do
  it "assembles the character description, idea, and required directions" do
    project = create(:project, :ready, default_tone: "playful")
    character = create(:character, :approved, project: project, name: "Rusty",
                                              description: "a cheerful fox",
                                              character_attributes: { "species" => "fox" })
    project.update!(active_character_id: character.id)
    video = create(:video, :with_idea, project: project, idea_text: "wave hello", tone: "playful")

    context = described_class.call(video)

    expect(context.character_description).to include("Rusty", "cheerful fox", "species: fox")
    expect(context.idea).to eq("wave hello")
    expect(context.duration_seconds).to eq(15)
    brief = context.to_brief
    expect(brief).to include("Camera direction", "Visual direction", "Character movement",
                             "Dialogue", "Audio style")
    expect(brief).to include("attached approved character reference image")
  end
end
