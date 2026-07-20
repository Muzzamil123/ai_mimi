module Videos
  # Updates a video's editable idea fields (title, typed idea, transcript,
  # language, tone). Used both for typing an idea and for editing a transcript
  # produced from speech. Once a usable idea exists, a draft advances to
  # `idea_ready`. Editing is refused while a transcription is in flight so an
  # in-progress transcript is not clobbered, and after the video has left the
  # idea stage (Phase 7+ prompt/generation states are terminal for idea edits).
  class UpdateVideoIdea < ApplicationService
    EDITABLE_STATUSES = %w[draft idea_ready failed].freeze

    def initialize(video, params, actor: nil)
      @video = video
      @params = params
      @actor = actor
    end

    def call
      unless EDITABLE_STATUSES.include?(@video.status)
        raise Videos::InvalidState, "This video's idea cannot be edited in its current state (#{@video.status})"
      end

      @video.assign_attributes(@params)
      @video.save!

      advance_to_idea_ready_if_ready
      @video
    end

    private

    # A draft (or a previously failed video) with a usable idea becomes ready.
    def advance_to_idea_ready_if_ready
      return unless @video.idea_present?
      return if @video.idea_ready?

      @video.transition_to!(:idea_ready, actor: @actor, reason: "idea provided")
    end
  end
end
