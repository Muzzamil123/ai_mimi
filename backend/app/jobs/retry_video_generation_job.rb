# Re-submits a variant that was reset to `pending` by VideoGenerations::
# RetryGeneration. Distinct, observable entry point for retries; behaviour is the
# shared submit step, so no logic is duplicated.
class RetryVideoGenerationJob < VideoGenerations::GenerationJob
  def perform(video_generation_id)
    submit(video_generation_id)
  end
end
