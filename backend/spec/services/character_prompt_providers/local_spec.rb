require "rails_helper"

RSpec.describe CharacterPromptProviders::Local do
  let(:character) do
    build(:character, name: "Rusty", description: "a brave fox",
                      character_attributes: { "mood" => "bold" },
                      style_preferences: { "palette" => "warm" })
  end

  it "builds a descriptive prompt from the character fields" do
    result = described_class.new.generate(character: character)

    expect(result.provider).to eq("local")
    expect(result.prompt).to include("Rusty")
    expect(result.prompt).to include("a brave fox")
    expect(result.prompt).to include("mood: bold")
    expect(result.estimated_cost).to eq(0)
  end

  it "incorporates rejection feedback when regenerating" do
    result = described_class.new.generate(character: character, feedback: "make it friendlier")

    expect(result.prompt).to include("make it friendlier")
  end
end
