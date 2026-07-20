require "zip"
require "stringio"

module VideoAssets
  # Bundles a set of ready assets into a single ZIP. Returns the archive bytes
  # (for a synchronous per-video "download all") or, given a storage key, stores
  # the archive and returns its Storage::Blob (for the async project archive).
  # Skips assets whose bytes are missing rather than failing the whole archive.
  class BuildArchive < ApplicationService
    def initialize(assets, storage: nil)
      @assets = Array(assets)
      @storage = storage || Storage.adapter
    end

    # Returns the ZIP as a binary String.
    def call
      buffer = Zip::OutputStream.write_buffer do |zip|
        used = Hash.new(0)
        @assets.each do |asset|
          next unless asset.ready?

          data = @storage.read(asset.storage_key)
          next if data.nil?

          zip.put_next_entry(unique_name(asset, used))
          zip.write(data)
        end
      end
      buffer.string
    end

    # Builds the archive and stores it under +key+, returning the Storage::Blob.
    def store_to(key)
      @storage.store(key: key, data: call, content_type: "application/zip")
    end

    private

    def unique_name(asset, used)
      base = asset.filename.presence || "output-#{asset.id}.mp4"
      used[base] += 1
      used[base] == 1 ? base : "#{File.basename(base, '.*')}-#{used[base]}#{File.extname(base)}"
    end
  end
end
