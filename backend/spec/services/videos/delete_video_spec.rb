require "rails_helper"

RSpec.describe Videos::DeleteVideo do
  let(:project) { create(:project, :ready) }

  it "deletes a draft video" do
    video = create(:video, project: project)

    described_class.call(video)

    expect(Video.exists?(video.id)).to be(false)
  end

  it "removes any uploaded idea audio from storage" do
    key = "videos/idea-audio/draft.webm"
    Storage.adapter.store(key: key, data: "bytes", content_type: "audio/webm")
    video = create(:video, project: project, idea_audio_storage_key: key)

    described_class.call(video)

    expect(Storage.adapter.exist?(key)).to be(false)
  end

  it "refuses to delete a non-draft video" do
    video = create(:video, :transcribed, project: project)

    expect { described_class.call(video) }
      .to raise_error(Videos::InvalidState, /Only draft videos/)
    expect(Video.exists?(video.id)).to be(true)
  end
end
