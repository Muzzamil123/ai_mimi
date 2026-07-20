require "open3"
require "tempfile"

module Media
  module Thumbnail
    # Production generator: shells out to ffmpeg to grab a frame ~1s in and encode
    # it as JPEG. Never used off-production (the Fake is the default). Raises on
    # failure so the caller can mark the asset's thumbnail step failed.
    class Ffmpeg
      def generate(data, mime_type: nil)
        input = Tempfile.new([ "thumb-src", ".bin" ], binmode: true)
        output = Tempfile.new([ "thumb-out", ".jpg" ], binmode: true)
        begin
          input.write(data)
          input.flush

          cmd = [
            "ffmpeg", "-y", "-i", input.path,
            "-ss", "1", "-frames:v", "1", "-f", "image2", output.path
          ]
          _stdout, stderr, status = Open3.capture3(*cmd)
          raise "ffmpeg thumbnail failed: #{stderr}" unless status.success?

          File.binread(output.path)
        ensure
          input.close
          input.unlink
          output.close
          output.unlink
        end
      end
    end
  end
end
