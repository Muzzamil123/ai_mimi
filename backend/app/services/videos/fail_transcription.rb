module Videos
  # Marks an in-flight transcription as failed (video -> failed) recording the
  # reason. Guarded by transcription_id so a late failure from a superseded
  # attempt cannot clobber a newer one. Idempotent: a no-op unless the video is
  # currently transcribing for this transcription_id.
  class FailTranscription < ApplicationService
    def initialize(video, transcription_id:, reason:, actor: nil)
      @video = video
      @transcription_id = transcription_id
      @reason = reason
      @actor = actor
    end

    def call
      return if @video.nil?
      return unless @video.transcribing? && @video.transcription_id == @transcription_id

      @video.update!(transcription_failure_reason: @reason.to_s.truncate(255))
      @video.transition_to!(:failed, actor: @actor, reason: "transcription failed")
      @video
    end
  end
end
