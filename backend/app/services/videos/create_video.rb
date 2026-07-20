module Videos
  # Creates a video under a project. Enforces the platform's core business rule:
  # no video may be created before the project's character is approved (the
  # project must be `ready`). Videos start as drafts; providing an idea or
  # uploading audio are separate, explicit steps.
  class CreateVideo < ApplicationService
    def initialize(project, params, actor: nil)
      @project = project
      @params = params
      @actor = actor
    end

    def call
      unless @project.generatable?
        raise Videos::InvalidState,
              "Videos can only be created once the project's character is approved"
      end

      @project.transaction do
        video = @project.videos.create!(@params)
        # Record the initial state so the video's history is complete from creation.
        video.status_changes.create!(to_status: video.status, actor: @actor, reason: "video created")
        video
      end
    end
  end
end
