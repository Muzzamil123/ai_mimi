require "rails_helper"

RSpec.describe Videos::FailTranscription do
  let(:project) { create(:project, :ready) }

  it "marks a transcribing video as failed with the reason" do
    video = create(:video, :transcribing, project: project)

    described_class.call(video, transcription_id: video.transcription_id, reason: "boom")

    video.reload
    expect(video).to be_failed
    expect(video.transcription_failure_reason).to eq("boom")
    expect(video.status_changes.last.to_status).to eq("failed")
  end

  it "is a no-op for a superseded transcription_id" do
    video = create(:video, :transcribing, project: project)

    described_class.call(video, transcription_id: "stale-id", reason: "late failure")

    expect(video.reload).to be_transcribing
  end

  it "is a no-op when the video is no longer transcribing" do
    video = create(:video, :transcribed, project: project)
    tid = video.transcription_id

    described_class.call(video, transcription_id: tid, reason: "late")

    expect(video.reload).to be_idea_ready
  end
end
