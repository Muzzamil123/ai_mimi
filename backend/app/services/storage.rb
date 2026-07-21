# Storage abstraction for generated binary assets (character images now; video
# renders later). A single entry point (`Storage.adapter`) hides the concrete
# backend so callers never depend on local disk vs. object storage. Swap the
# backend via the STORAGE_BACKEND env var; add S3-compatible adapters here
# without touching call sites.
module Storage
  class Error < StandardError; end

  # A stored object's metadata, returned by every adapter's #store.
  Blob = Struct.new(:key, :byte_size, :checksum, :content_type, keyword_init: true)

  class << self
    def adapter
      @adapter ||= build_adapter
    end

    # Test/boot hook so specs can inject an in-memory adapter.
    attr_writer :adapter

    def reset_adapter!
      @adapter = nil
    end

    private

    def build_adapter
      case ENV.fetch("STORAGE_BACKEND", "local")
      when "local"
        LocalDisk.new
      when "s3"
        S3.new
      else
        raise Error, "Unknown storage backend: #{ENV['STORAGE_BACKEND']}"
      end
    end
  end
end
