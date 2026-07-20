require "digest"

module VideoGenerationProviders
  # Deterministic in-process provider for development and tests. Accepts a job and
  # reports it completed, so the full pipeline (batch, submit, poll, finalize)
  # runs end-to-end with no network or credentials. The job id is derived from the
  # prompt + options so the same variant maps to a stable id.
  class Fake < Base
    def create_generation(prompt:, reference_image:, options: {})
      # Guard the mandatory inputs so tests catch a pipeline that forgets to
      # attach the approved character image or prompt.
      raise Error.new("Missing prompt", retryable: false) if prompt.to_s.strip.empty?
      raise Error.new("Missing reference image", retryable: false) if reference_image.nil?

      digest = Digest::SHA256.hexdigest("#{prompt}:#{options[:aspect_ratio]}:#{options[:variation_number]}")

      Result.new(
        provider_job_id: "fake-job-#{digest[0, 16]}",
        provider_request_id: "fake-req-#{digest[0, 12]}",
        provider: "fake",
        model: "fake-video-1",
        estimated_cost: BigDecimal("0")
      )
    end

    # Fake jobs complete immediately so the local pipeline terminates.
    def fetch_status(job_id:)
      StatusResult.new(state: :completed, progress: 100, asset_ref: "#{job_id}/asset")
    end

    def fetch_asset(job_id:)
      # A tiny, valid-ish placeholder; real asset download/validation is Phase 9.
      { data: "FAKE-MP4-#{job_id}".b, mime_type: "video/mp4" }
    end
  end
end
