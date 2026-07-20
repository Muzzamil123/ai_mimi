module VideoGenerationProviders
  # Interface implemented by every video-generation provider.
  class Base
    # Submits a generation job. +prompt+ is the approved prompt text, +reference_image+
    # is a Hash describing the project's approved character image ({ data:, mime_type:,
    # storage_key: }), and +options+ carries aspect_ratio, variation_number, and
    # duration_seconds. Returns a VideoGenerationProviders::Result; raises ::Error
    # (with retryable / code) on failure.
    def create_generation(prompt:, reference_image:, options: {})
      raise NotImplementedError
    end

    # Returns a VideoGenerationProviders::StatusResult for a submitted job.
    def fetch_status(job_id:)
      raise NotImplementedError
    end

    # Returns the finished asset bytes/URL for a completed job. Used by the
    # download step in Phase 9; not called during Phase 8 generation.
    def fetch_asset(job_id:)
      raise NotImplementedError
    end
  end
end
