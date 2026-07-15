require "digest"
require "base64"

module CharacterImageProviders
  # Deterministic in-process provider for development and tests. Returns a valid
  # 1x1 PNG so the full pipeline (store, download, dimensions, checksum) runs
  # end-to-end with no network or credentials. The request id is derived from the
  # prompt so regenerating with a changed prompt yields a distinct asset id.
  class Fake < Base
    # A real, decodable 1x1 transparent PNG.
    PNG_1PX_BASE64 =
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==".freeze

    def generate(prompt:, options: {})
      digest = Digest::SHA256.hexdigest(prompt.to_s)

      Result.new(
        image_data: Base64.decode64(PNG_1PX_BASE64),
        mime_type: "image/png",
        provider: "fake",
        model: "fake-image-1",
        provider_request_id: "fake-#{digest[0, 12]}",
        provider_asset_id: "fake-asset-#{digest[0, 12]}",
        estimated_cost: BigDecimal("0")
      )
    end
  end
end
