require "fileutils"
require "digest"

module Storage
  # Filesystem-backed storage used in development, test, and single-node
  # deployments. Keys map to paths under a configurable root; nested keys create
  # intermediate directories. Production S3/GCS adapters implement the same
  # interface without changing callers.
  class LocalDisk < Base
    def initialize(root: nil)
      @root = Pathname.new(root || ENV["STORAGE_ROOT"] || Rails.root.join("storage").to_s)
    end

    def store(key:, data:, content_type: nil)
      path = path_for(key)
      FileUtils.mkdir_p(path.dirname)
      File.binwrite(path, data)

      Blob.new(
        key: key,
        byte_size: data.bytesize,
        checksum: Digest::SHA256.hexdigest(data),
        content_type: content_type
      )
    rescue SystemCallError => e
      raise Storage::Error, "Failed to store '#{key}': #{e.message}"
    end

    def read(key)
      File.binread(path_for(key))
    rescue Errno::ENOENT
      nil
    rescue SystemCallError => e
      raise Storage::Error, "Failed to read '#{key}': #{e.message}"
    end

    def delete(key)
      File.delete(path_for(key))
      true
    rescue Errno::ENOENT
      false
    end

    def exist?(key)
      File.exist?(path_for(key))
    end

    private

    # Resolves +key+ to an absolute path and refuses any key that would escape
    # the storage root (path traversal defence).
    def path_for(key)
      cleaned = key.to_s.gsub(%r{\A/+}, "")
      path = @root.join(cleaned).expand_path

      unless path.to_s.start_with?(@root.expand_path.to_s + File::SEPARATOR)
        raise Storage::Error, "Invalid storage key: #{key}"
      end

      path
    end
  end
end
