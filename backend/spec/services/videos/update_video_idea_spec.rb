require "rails_helper"

RSpec.describe Videos::UpdateVideoIdea do
  let(:project) { create(:project, :ready) }

  it "advances a draft to idea_ready when a typed idea is provided" do
    video = create(:video, project: project)

    described_class.call(video, { idea_text: "A fun launch clip" }, actor: project.user)

    expect(video.reload).to be_idea_ready
    expect(video.idea_text).to eq("A fun launch clip")
    expect(video.status_changes.last.to_status).to eq("idea_ready")
  end

  it "keeps the video in idea_ready when editing the transcript" do
    video = create(:video, :transcribed, project: project)

    described_class.call(video, { transcript: "Edited transcript" })

    expect(video.reload).to be_idea_ready
    expect(video.transcript).to eq("Edited transcript")
  end

  it "updates metadata without advancing when no idea is present" do
    video = create(:video, project: project)

    described_class.call(video, { title: "Renamed" })

    expect(video.reload.title).to eq("Renamed")
    expect(video).to be_draft
  end

  it "recovers a failed video to idea_ready when a typed idea is provided" do
    video = create(:video, :failed, project: project)

    described_class.call(video, { idea_text: "typed instead" })

    expect(video.reload).to be_idea_ready
  end

  it "refuses to edit while transcribing" do
    video = create(:video, :transcribing, project: project)

    expect { described_class.call(video, { idea_text: "nope" }) }
      .to raise_error(Videos::InvalidState, /cannot be edited/)
  end

  it "surfaces validation errors" do
    video = create(:video, project: project)

    expect { described_class.call(video, { language: "klingon" }) }
      .to raise_error(ActiveRecord::RecordInvalid)
  end
end
