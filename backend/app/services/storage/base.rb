module Storage
  # Interface every storage backend implements. Subclasses raise
  # Storage::Error on failure so callers can handle storage problems uniformly.
  class Base
    # Persists +data+ (a binary String) under +key+ and returns a Storage::Blob.
    def store(key:, data:, content_type: nil)
      raise NotImplementedError
    end

    # Returns the stored bytes as a String, or nil if the key is absent.
    def read(key)
      raise NotImplementedError
    end

    def delete(key)
      raise NotImplementedError
    end

    def exist?(key)
      raise NotImplementedError
    end
  end
end
