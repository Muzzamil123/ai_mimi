require "digest"

module VideoGenerationProviders
  # Deterministic in-process provider for development and tests. Accepts a job and
  # reports it completed, so the full pipeline (batch, submit, poll, finalize,
  # then Phase 9 download/validate/store) runs end-to-end with no network or
  # credentials. The job id encodes the aspect + variation so fetch_asset can
  # return a fake video whose dimensions match the requested aspect ratio.
  class Fake < Base
    # Fake portrait dimensions per aspect ratio (exact ratios).
    DIMENSIONS = { "3:4" => [ 720, 960 ], "9:16" => [ 720, 1280 ] }.freeze

    def create_generation(prompt:, reference_image:, options: {})
      # Guard the mandatory inputs so tests catch a pipeline that forgets to
      # attach the approved character image or prompt.
      raise Error.new("Missing prompt", retryable: false) if prompt.to_s.strip.empty?
      raise Error.new("Missing reference image", retryable: false) if reference_image.nil?

      aspect = options[:aspect_ratio].to_s
      variation = options[:variation_number]
      digest = Digest::SHA256.hexdigest("#{prompt}:#{aspect}:#{variation}")

      Result.new(
        provider_job_id: "fake-job-#{aspect_token(aspect)}-#{variation}-#{digest[0, 12]}",
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

    # Returns a small fake video whose header carries the duration + dimensions
    # the Media::VideoInfo::Fake inspector reads back, so validation is genuinely
    # exercised. Real MP4 bytes arrive here only with a real provider.
    def fetch_asset(job_id:)
      width, height = DIMENSIONS.fetch(aspect_from(job_id), [ 720, 960 ])
      header = "FAKEVID;duration=#{Video::DEFAULT_DURATION_SECONDS};width=#{width};height=#{height};"
      { data: "#{header}fake-bytes-#{job_id}".b, mime_type: "video/mp4" }
    end

    private

    def aspect_token(aspect)
      aspect.tr(":", "x")
    end

    # Recovers the aspect ratio ("3:4"/"9:16") from a fake job id.
    def aspect_from(job_id)
      token = job_id.to_s[/fake-job-(\dx\d+)-/, 1]
      token.to_s.tr("x", ":")
    end
  end
end
