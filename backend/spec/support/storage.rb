require "digest"

# In-memory storage backend so specs never touch the filesystem and every part
# of the pipeline (store -> read) shares one instance within an example.
class InMemoryStorage < Storage::Base
  attr_reader :data

  def initialize
    @data = {}
  end

  def store(key:, data:, content_type: nil)
    @data[key] = data.b
    Storage::Blob.new(
      key: key,
      byte_size: data.bytesize,
      checksum: Digest::SHA256.hexdigest(data),
      content_type: content_type
    )
  end

  def read(key)
    @data[key]
  end

  def delete(key)
    !!@data.delete(key)
  end

  def exist?(key)
    @data.key?(key)
  end
end

RSpec.configure do |config|
  config.before do
    Storage.adapter = InMemoryStorage.new
  end

  config.after do
    Storage.reset_adapter!
  end
end
