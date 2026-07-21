module VideoGenerations
  # Submits one variant to the provider. Always attaches the project's approved
  # character image (read from storage) as the reference, plus the approved prompt
  # and the aspect/variation/duration options, then moves the record to
  # `processing`. Kept separate from the job so the provider call can be unit
  # tested. Idempotent: only acts on a `pending` record.
  class SubmitGeneration < ApplicationService
    def initialize(video_generation, provider: nil, storage: nil)
      @generation = video_generation
      @provider = provider || VideoGenerationProviders.build
      @storage = storage || Storage.adapter
    end

    def call
      return @generation unless @generation.pending?

      reference = reference_image!
      @generation.update!(attempt_count: @generation.attempt_count + 1)

      result = @provider.create_generation(
        prompt: @generation.prompt.content,
        reference_image: reference,
        options: {
          aspect_ratio: @generation.aspect_ratio,
          variation_number: @generation.variation_number,
          duration_seconds: @generation.duration_seconds
        }
      )

      @generation.update!(
        provider: result.provider,
        provider_model: result.model,
        provider_job_id: result.provider_job_id,
        provider_request_id: result.provider_request_id,
        estimated_cost: result.estimated_cost,
        error_code: nil,
        error_message: nil
      )
      @generation.transition_to!(:processing)
      record_usage(result)
      @generation
    end

    private

    # Ledger the billable render (Phase 12), keyed by the generation so a retried
    # submit updates the same row rather than double-counting.
    def record_usage(result)
      Usage::Record.call(
        source: @generation,
        provider: result.provider,
        service_type: "video_generation",
        model: result.model,
        user: @generation.project&.user,
        project: @generation.project,
        video: @generation.video,
        provider_request_id: result.provider_request_id,
        generated_seconds: @generation.duration_seconds,
        units: 1,
        provider_reported_cost: result.estimated_cost
      )
    end

    # The approved character image bytes handed to the provider. Every generated
    # video must use the project's approved character (mandatory attachment).
    def reference_image!
      image = @generation.character.latest_image
      raise VideoGenerations::InvalidState, "Approved character has no image" if image.nil?

      data = @storage.read(image.storage_key)
      raise Storage::Error, "Character image missing from storage: #{image.storage_key}" if data.nil?

      { data: data, mime_type: image.mime_type, storage_key: image.storage_key }
    end
  end
end
