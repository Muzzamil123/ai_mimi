require "rails_helper"

RSpec.describe "VideoGenerations submit + poll" do
  def generating_record
    video = ready_to_generate_video
    video.update!(status: :generating)
    create(:video_generation,
           video: video, project: video.project,
           character: video.project.active_character, prompt: video.active_prompt,
           aspect_ratio: "3:4", variation_number: 1)
  end

  describe VideoGenerations::SubmitGeneration do
    it "submits with the approved character image and moves to processing" do
      record = generating_record
      provider = instance_double(VideoGenerationProviders::Fake)
      captured = {}
      allow(provider).to receive(:create_generation) do |prompt:, reference_image:, options:|
        captured = { prompt: prompt, reference_image: reference_image, options: options }
        VideoGenerationProviders::Result.new(provider_job_id: "job-1", provider: "fake", model: "m")
      end

      described_class.call(record, provider: provider)

      expect(record.reload).to be_processing
      expect(record.provider_job_id).to eq("job-1")
      expect(record.attempt_count).to eq(1)
      expect(captured[:prompt]).to eq(record.prompt.content)
      expect(captured[:reference_image][:data]).to eq("PNG-BYTES")
      expect(captured[:options][:aspect_ratio]).to eq("3:4")
    end

    it "raises when the character image bytes are missing from storage" do
      record = generating_record
      Storage.adapter.delete(record.character.latest_image.storage_key)

      expect { described_class.call(record) }.to raise_error(Storage::Error)
    end
  end

  describe VideoGenerations::PollStatus do
    it "completes the record when the provider reports completed" do
      record = generating_record
      record.update!(provider_job_id: "job-1")
      record.transition_to!(:processing)

      described_class.new(record).call # fake provider returns completed

      expect(record.reload).to be_completed
      expect(record.progress).to eq(100)
    end

    it "updates progress while still processing" do
      record = generating_record
      record.update!(provider_job_id: "job-1")
      record.transition_to!(:processing)
      provider = instance_double(VideoGenerationProviders::Fake)
      allow(provider).to receive(:fetch_status)
        .and_return(VideoGenerationProviders::StatusResult.new(state: :processing, progress: 55))

      described_class.new(record, provider: provider).call

      expect(record.reload).to be_processing
      expect(record.progress).to eq(55)
    end
  end
end
