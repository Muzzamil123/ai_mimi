require "digest"

module SpeechToTextProviders
  # Deterministic in-process provider for development and tests. Returns a stable
  # transcript derived from the audio bytes so the full pipeline (upload, store,
  # transcribe, edit) runs end-to-end with no network or credentials. The request
  # id is derived from the audio so re-uploading different audio yields a distinct
  # transcript and id.
  class Fake < Base
    def transcribe(audio_data:, mime_type:, language: nil, filename: nil)
      digest = Digest::SHA256.hexdigest(audio_data.to_s)

      Result.new(
        text: "This is a transcribed idea (fake provider) [#{digest[0, 8]}].",
        language: language,
        provider: "fake",
        model: "fake-transcribe-1",
        provider_request_id: "fake-#{digest[0, 12]}",
        duration_seconds: nil,
        estimated_cost: BigDecimal("0")
      )
    end
  end
end
