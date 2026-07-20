require "base64"

module Media
  # Abstraction for extracting a poster thumbnail (JPEG bytes) from a video.
  # Production uses ffmpeg; dev/test uses a Fake that returns a real 1x1 JPEG, so
  # the pipeline runs with no ffmpeg dependency.
  module Thumbnail
    MIME_TYPE = "image/jpeg".freeze

    class << self
      def generate(data, mime_type: nil)
        build.generate(data, mime_type: mime_type)
      end

      def build(name: default_backend)
        case name.to_s
        when "ffmpeg" then Ffmpeg.new
        when "fake" then Fake.new
        else raise ArgumentError, "Unknown thumbnail generator: #{name}"
        end
      end

      def default_backend
        ENV.fetch("VIDEO_THUMBNAILER", Rails.env.production? ? "ffmpeg" : "fake")
      end
    end

    # Deterministic generator for dev/test: a valid 1x1 JPEG.
    class Fake
      JPEG_1PX_BASE64 =
        "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAP//////////////////////////////////" \
        "////////////////////////////////////////////////////wgALCAABAAEBAREA" \
        "/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxA=".freeze

      def generate(_data, mime_type: nil)
        Base64.decode64(JPEG_1PX_BASE64)
      end
    end
  end
end
