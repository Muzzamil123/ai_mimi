require "rails_helper"
require "base64"

# Every billable provider call must create a ProviderUsage row (Phase 12 DoD).
# These drive each seam service end-to-end (fake/local providers) and assert the
# ledger entry appears with the right attribution and service type.
RSpec.describe "Usage recording at provider seams", type: :service do
  it "records text_generation when a prompt is generated" do
    video = create(:video, :with_idea, status: :generating_prompt)
    prompt = create(:prompt, :generating, video: video, content: nil)

    expect { Prompts::GenerateContent.call(prompt) }
      .to change(ProviderUsage, :count).by(1)

    usage = ProviderUsage.find_by(source: prompt)
    expect(usage.service_type).to eq("text_generation")
    expect(usage.project_id).to eq(video.project_id)
    expect(usage.user_id).to eq(video.project.user_id)
  end

  it "records video_generation when a variant is submitted" do
    video = ready_to_generate_video
    video.update!(status: :generating)
    record = create(:video_generation, video: video, project: video.project,
                                       character: video.project.active_character, prompt: video.active_prompt)

    expect { VideoGenerations::SubmitGeneration.call(record) }
      .to change(ProviderUsage, :count).by(1)

    usage = ProviderUsage.find_by(source: record)
    expect(usage.service_type).to eq("video_generation")
    expect(usage.generated_seconds).to eq(15)
  end

  it "records speech_to_text when audio is transcribed" do
    project = create(:project, :ready)
    key = "videos/idea-audio/seam.webm"
    Storage.adapter.store(key: key, data: "audio-bytes", content_type: "audio/webm")
    video = create(:video, :transcribing, project: project, idea_audio_storage_key: key)

    expect { Videos::TranscribeAudio.call(video, storage_key: key, mime_type: "audio/webm") }
      .to change(ProviderUsage, :count).by(1)

    expect(ProviderUsage.find_by(source: video).service_type).to eq("speech_to_text")
  end

  it "records character_image when a generated image is stored" do
    character = create(:character, :generating, provider: "gemini", provider_model: "imagen",
                                                estimated_cost: "0.04")
    # The pipeline has the project mid-initialization when the image is stored.
    character.project.update!(status: :initializing_character)
    key = "characters/#{character.id}/source.png"
    png = Base64.decode64(
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M8AAAMBAQDJ/pLvAAAAAElFTkSuQmCC"
    )
    Storage.adapter.store(key: key, data: png, content_type: "image/png")

    expect { Characters::StoreGeneratedImage.call(character, storage_key: key, mime_type: "image/png") }
      .to change(ProviderUsage, :count).by(1)

    usage = ProviderUsage.find_by(source_type: "CharacterImage")
    expect(usage.service_type).to eq("character_image")
    expect(usage.generated_images).to eq(1)
    expect(usage.project_id).to eq(character.project_id)
  end
end
