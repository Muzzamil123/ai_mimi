require "rails_helper"

RSpec.describe Videos::UploadAudio do
  include ActiveJob::TestHelper

  let(:project) { create(:project, :ready) }
  let(:video) { create(:video, project: project) }

  # Minimal stand-in for an ActionDispatch::Http::UploadedFile.
  def uploaded(bytes: "RIFFfakeaudio", content_type: "audio/webm")
    io = StringIO.new(bytes)
    def io.content_type = @content_type
    io.instance_variable_set(:@content_type, content_type)
    io
  end

  it "stores the audio, moves to transcribing, and enqueues processing" do
    file = uploaded

    expect { described_class.call(video, file: file, actor: project.user) }
      .to have_enqueued_job(ProcessVideoAudioUploadJob)
      .with(video.id, kind_of(String), kind_of(String), "audio/webm")

    video.reload
    expect(video).to be_transcribing
    expect(video.transcription_id).to be_present
    expect(video.idea_audio_storage_key).to be_present
    expect(Storage.adapter.read(video.idea_audio_storage_key)).to eq("RIFFfakeaudio")
    expect(video.status_changes.last.to_status).to eq("transcribing")
  end

  it "rotates the transcription_id on re-upload so stale jobs are superseded" do
    described_class.call(video, file: uploaded)
    first_id = video.reload.transcription_id

    described_class.call(video, file: uploaded(bytes: "second"))

    expect(video.reload.transcription_id).not_to eq(first_id)
    expect(video).to be_transcribing
  end

  it "rejects an unsupported audio type" do
    expect { described_class.call(video, file: uploaded(content_type: "application/pdf")) }
      .to raise_error(Videos::InvalidAudio, /Unsupported audio type/)
    expect(video.reload).to be_draft
  end

  it "rejects a non-audio file spoofing an audio Content-Type" do
    spoofed = uploaded(bytes: "%PDF-1.7 fake document", content_type: "audio/webm")

    expect { described_class.call(video, file: spoofed) }
      .to raise_error(Videos::InvalidAudio, /does not appear to be audio/)
    expect(video.reload).to be_draft
  end

  it "reclaims the superseded audio blob on re-upload" do
    described_class.call(video, file: uploaded)
    first_key = video.reload.idea_audio_storage_key

    described_class.call(video, file: uploaded(bytes: "second take"))

    expect(Storage.adapter.exist?(first_key)).to be(false)
    expect(Storage.adapter.exist?(video.reload.idea_audio_storage_key)).to be(true)
  end

  it "rejects an empty file" do
    expect { described_class.call(video, file: uploaded(bytes: "")) }
      .to raise_error(Videos::InvalidAudio, /empty/)
  end

  it "rejects a file over the size limit" do
    allow(Videos).to receive(:max_audio_bytes).and_return(4)

    expect { described_class.call(video, file: uploaded(bytes: "way too big")) }
      .to raise_error(Videos::InvalidAudio, /too large/)
  end

  it "refuses to upload for a video in an incompatible state" do
    approved_stage = create(:video, project: project, status: :generating_prompt)

    expect { described_class.call(approved_stage, file: uploaded) }
      .to raise_error(Videos::InvalidState)
  end
end
