require "open3"
require "json"
require "tempfile"

module Media
  module VideoInfo
    # Production inspector: shells out to ffprobe to read duration/dimensions from
    # the video stream. Never used off-production (the Fake is the default), so the
    # test suite has no ffmpeg dependency.
    class Ffprobe
      def probe(data, mime_type: nil)
        with_tempfile(data) do |path|
          payload = run(path)
          stream = Array(payload["streams"]).find { |s| s["codec_type"] == "video" }
          return Result.new(playable: false) if stream.nil?

          Result.new(
            duration_seconds: (payload.dig("format", "duration") || stream["duration"]).to_f.round,
            width: stream["width"],
            height: stream["height"],
            playable: true
          )
        end
      rescue Errno::ENOENT, JSON::ParserError
        Result.new(playable: false)
      end

      private

      def run(path)
        cmd = [
          "ffprobe", "-v", "quiet", "-print_format", "json",
          "-show_format", "-show_streams", path
        ]
        stdout, _stderr, status = Open3.capture3(*cmd)
        return {} unless status.success?

        JSON.parse(stdout)
      end

      def with_tempfile(data)
        file = Tempfile.new([ "video-probe", ".bin" ], binmode: true)
        file.write(data)
        file.flush
        yield file.path
      ensure
        file&.close
        file&.unlink
      end
    end
  end
end
