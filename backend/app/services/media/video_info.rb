module Media
  # Abstraction for probing a video's technical metadata (duration, dimensions,
  # playability) without hard-coding a tool. Production uses ffprobe; dev/test
  # uses a deterministic Fake that reads a small header the fake video provider
  # writes, so the validation pipeline runs end-to-end with no ffmpeg dependency.
  module VideoInfo
    Result = Struct.new(:duration_seconds, :width, :height, :playable, keyword_init: true) do
      def playable? = !!playable
    end

    class << self
      def probe(data, mime_type: nil)
        build.probe(data, mime_type: mime_type)
      end

      def build(name: default_backend)
        case name.to_s
        when "ffprobe" then Ffprobe.new
        when "fake" then Fake.new
        else raise ArgumentError, "Unknown video inspector: #{name}"
        end
      end

      def default_backend
        ENV.fetch("VIDEO_INSPECTOR", Rails.env.production? ? "ffprobe" : "fake")
      end
    end
  end
end
