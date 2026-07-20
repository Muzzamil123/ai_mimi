module Videos
  # Deletes a draft video. Only drafts are deletable (mirrors project deletion
  # rules); once a video has an idea/transcript or has progressed further it is
  # kept for its history and outputs. Cleans up any uploaded idea audio from
  # storage so no orphaned blobs are left behind.
  class DeleteVideo < ApplicationService
    def initialize(video, storage: nil)
      @video = video
      @storage = storage || Storage.adapter
    end

    def call
      unless @video.draft?
        raise Videos::InvalidState, "Only draft videos can be deleted"
      end

      key = @video.idea_audio_storage_key
      @video.destroy!
      @storage.delete(key) if key.present?
      true
    end
  end
end
