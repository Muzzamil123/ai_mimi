module Media
  module VideoInfo
    # Deterministic inspector for dev/test. Reads the header the fake video
    # provider writes ("FAKEVID;duration=15;width=720;height=960;"). Bytes without
    # that header are treated as an unplayable/invalid video, so "invalid video"
    # cases are exercisable without real media.
    class Fake
      HEADER = /\AFAKEVID;duration=(\d+);width=(\d+);height=(\d+);/

      def probe(data, mime_type: nil)
        match = HEADER.match(data.to_s)
        return Result.new(playable: false) if match.nil?

        Result.new(
          duration_seconds: match[1].to_i,
          width: match[2].to_i,
          height: match[3].to_i,
          playable: true
        )
      end
    end
  end
end
