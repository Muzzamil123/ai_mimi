require "rails_helper"

RSpec.describe Videos::CreateVideo do
  it "creates a draft video under a ready project and records initial history" do
    project = create(:project, :ready)

    video = described_class.call(project, { title: "Intro" }, actor: project.user)

    expect(video).to be_persisted
    expect(video).to be_draft
    expect(video.status_changes.last.to_status).to eq("draft")
  end

  it "inherits project defaults" do
    project = create(:project, :ready, default_language: "punjabi", default_tone: "warm")

    video = described_class.call(project, { title: "Intro" })

    expect(video.language).to eq("punjabi")
    expect(video.tone).to eq("warm")
    expect(video.duration_seconds).to eq(15)
  end

  it "allows multiple videos per project" do
    project = create(:project, :ready)

    described_class.call(project, { title: "One" })
    described_class.call(project, { title: "Two" })

    expect(project.videos.count).to eq(2)
  end

  it "refuses to create a video before the character is approved" do
    project = create(:project, status: :draft)

    expect { described_class.call(project, { title: "Too soon" }) }
      .to raise_error(Videos::InvalidState, /character is approved/)
    expect(project.videos).to be_empty
  end
end
