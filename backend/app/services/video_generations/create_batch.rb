module VideoGenerations
  # Creates the four required generation records (two aspect ratios × two
  # variations) for the video's approved prompt + approved character, then moves
  # the video to `generating` and enqueues a submit job per record.
  #
  # Idempotent: each record is find_or_created by its deterministic
  # idempotency_key, so a re-run (retry of the batch job, or a repeated request)
  # never creates duplicates for the same (video, prompt, character, aspect,
  # variation).
  class CreateBatch < ApplicationService
    def initialize(video, actor: nil)
      @video = video
      @project = video.project
      @actor = actor
    end

    def call
      prompt = @video.active_prompt
      character = @project.active_character
      return if prompt.nil? || character.nil?

      records = []
      @video.with_lock do
        # Only act while the video is awaiting/undergoing generation for this
        # batch; a superseded/cancelled run safely no-ops.
        break unless @video.queued? || @video.generating?

        records = VideoGenerations.variant_matrix.map do |variant|
          find_or_create_record(prompt, character, variant)
        end

        @video.transition_to!(:generating, actor: @actor, reason: "video generation started") if @video.queued?
      end

      records.select(&:pending?).each { |record| SubmitVideoGenerationJob.perform_later(record.id) }
      records
    end

    private

    def find_or_create_record(prompt, character, variant)
      key = VideoGenerations.idempotency_key(
        video_id: @video.id,
        prompt_id: prompt.id,
        character_id: character.id,
        aspect_ratio: variant[:aspect_ratio],
        variation_number: variant[:variation_number]
      )

      VideoGeneration.create_with(
        video: @video,
        project: @project,
        character: character,
        prompt: prompt,
        aspect_ratio: variant[:aspect_ratio],
        variation_number: variant[:variation_number],
        # Phase 1 generates 15-second outputs only, regardless of any future
        # long-form video duration.
        duration_seconds: Video::DEFAULT_DURATION_SECONDS,
        provider: VideoGenerationProviders.default_provider
      ).find_or_create_by!(idempotency_key: key)
    end
  end
end
