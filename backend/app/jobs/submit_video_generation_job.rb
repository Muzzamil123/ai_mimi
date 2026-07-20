# Submits a single (initial) variant to the provider and starts polling.
# Behaviour lives in the shared VideoGenerations::GenerationJob base.
class SubmitVideoGenerationJob < VideoGenerations::GenerationJob
  def perform(video_generation_id)
    submit(video_generation_id)
  end
end
