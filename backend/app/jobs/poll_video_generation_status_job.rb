# Polls the provider for a processing variant. While the job is still running it
# re-enqueues itself with a delay, up to a bounded number of polls; past that
# deadline it marks the variant failed (timeout) so it never polls forever.
# Terminal states (completed/failed) finalize the video via VideoGenerations::
# PollStatus.
class PollVideoGenerationStatusJob < VideoGenerations::GenerationJob
  DEFAULT_MAX_POLLS = 40
  DEFAULT_INTERVAL_SECONDS = 15

  def perform(video_generation_id, poll_count = 0)
    guard(video_generation_id) do |generation|
      next unless generation.processing?

      poller = VideoGenerations::PollStatus.new(generation)
      status = poller.call

      next unless status&.processing?

      if poll_count >= max_polls
        poller.fail!(code: "timeout", message: "generation did not finish within the polling window")
      else
        self.class.set(wait: interval_seconds).perform_later(video_generation_id, poll_count + 1)
      end
    end
  end

  private

  def max_polls
    Integer(ENV.fetch("VIDEO_GENERATION_MAX_POLLS", DEFAULT_MAX_POLLS))
  rescue ArgumentError, TypeError
    DEFAULT_MAX_POLLS
  end

  def interval_seconds
    Integer(ENV.fetch("VIDEO_GENERATION_POLL_INTERVAL_SECONDS", DEFAULT_INTERVAL_SECONDS))
  rescue ArgumentError, TypeError
    DEFAULT_INTERVAL_SECONDS
  end
end
