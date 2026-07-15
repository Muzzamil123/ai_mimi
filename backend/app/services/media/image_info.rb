module Media
  # Extracts pixel dimensions from raw image bytes without an external image
  # library (no ImageMagick dependency). Supports PNG and JPEG, which cover the
  # formats returned by the character image providers. Returns nil dimensions for
  # unrecognized data rather than raising.
  class ImageInfo
    Dimensions = Struct.new(:width, :height, keyword_init: true)

    PNG_SIGNATURE = "\x89PNG\r\n\x1a\n".b.freeze

    def self.dimensions(data)
      new(data).dimensions
    end

    def initialize(data)
      @data = data.to_s.b
    end

    def dimensions
      return png_dimensions if png?
      return jpeg_dimensions if jpeg?

      Dimensions.new(width: nil, height: nil)
    end

    private

    def png?
      @data.byteslice(0, 8) == PNG_SIGNATURE
    end

    def jpeg?
      @data.byteslice(0, 2) == "\xFF\xD8".b
    end

    # PNG IHDR chunk holds width/height as big-endian 32-bit ints at bytes 16..23.
    def png_dimensions
      width, height = @data.byteslice(16, 8).unpack("N2")
      Dimensions.new(width: width, height: height)
    end

    # Walk JPEG segment markers to the Start-Of-Frame (SOFn) segment, which
    # carries height then width as big-endian 16-bit ints.
    def jpeg_dimensions
      offset = 2
      bytes = @data.bytesize

      while offset < bytes
        return unknown unless @data.getbyte(offset) == 0xFF

        marker = @data.getbyte(offset + 1)
        offset += 2

        # Standalone markers without a length payload.
        next if marker.nil? || (0xD0..0xD9).cover?(marker)

        length = @data.byteslice(offset, 2).to_s.unpack1("n")
        break if length.nil?

        if sof_marker?(marker)
          height, width = @data.byteslice(offset + 3, 4).to_s.unpack("n2")
          return Dimensions.new(width: width, height: height)
        end

        offset += length
      end

      unknown
    end

    def sof_marker?(marker)
      (0xC0..0xCF).cover?(marker) && ![ 0xC4, 0xC8, 0xCC ].include?(marker)
    end

    def unknown
      Dimensions.new(width: nil, height: nil)
    end
  end
end
