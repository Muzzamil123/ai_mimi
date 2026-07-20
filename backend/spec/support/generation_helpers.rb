# Helpers for Phase 8 video-generation specs: builds a video that is ready to
# generate (project ready, approved character with a stored image, and an
# approved active prompt) and stores the character image bytes so the submit step
# can read a real reference image.
module GenerationHelpers
  def ready_to_generate_video(user: nil, storage_bytes: "PNG-BYTES")
    project = create(:project, :ready, user: user || create(:user))
    character = create(:character, :approved, project: project)
    image = create(:character_image, character: character)
    Storage.adapter.store(key: image.storage_key, data: storage_bytes, content_type: image.mime_type)
    project.update!(active_character_id: character.id)

    video = create(:video, :with_idea, project: project, status: :prompt_ready)
    prompt = create(:prompt, :approved, video: video)
    video.update!(active_prompt_id: prompt.id)
    video
  end
end

RSpec.configure do |config|
  config.include GenerationHelpers
end
