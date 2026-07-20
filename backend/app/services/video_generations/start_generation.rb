module VideoGenerations
  # Entry point for producing a video's four outputs. Enforces the mandatory
  # inputs — an approved prompt AND the project's approved character (with a
  # stored image) — then moves the video to `queued` and hands off to the batch
  # job. All preconditions are re-verified under the video lock so a concurrent
  # start can't launch two batches (duplicate-request prevention).
  class StartGeneration < ApplicationService
    def initialize(video, actor: nil)
      @video = video
      @project = video.project
      @actor = actor
    end

    def call
      prompt = @video.active_prompt
      character = @project.active_character

      unless prompt&.approved?
        raise VideoGenerations::InvalidState, "Approve a prompt before generating videos"
      end
      unless character&.approved?
        raise VideoGenerations::InvalidState, "The project's character must be approved before generating videos"
      end
      unless character.latest_image.present?
        raise VideoGenerations::InvalidState, "The approved character has no image to use as a reference"
      end

      @video.with_lock do
        unless @video.prompt_ready?
          raise VideoGenerations::InvalidState, startable_error_message
        end

        @video.transition_to!(:queued, actor: @actor, reason: "video generation requested")
      end

      CreateVideoGenerationBatchJob.perform_later(@video.id)
      @video
    end

    private

    def startable_error_message
      if @video.queued? || @video.generating?
        "Video generation is already in progress"
      else
        "Videos can only be generated from an approved prompt (current state: #{@video.status})"
      end
    end
  end
end
