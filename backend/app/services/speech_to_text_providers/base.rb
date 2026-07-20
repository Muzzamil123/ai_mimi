module SpeechToTextProviders
  # Interface implemented by every speech-to-text provider.
  class Base
    # Transcribes the audio in +audio_data+ (raw binary String) recorded/uploaded
    # as +mime_type+, optionally hinting the spoken +language+ and a +filename+
    # for providers that infer the format from it. Returns a
    # SpeechToTextProviders::Result; raises ::Error / ::TimeoutError on failure.
    def transcribe(audio_data:, mime_type:, language: nil, filename: nil)
      raise NotImplementedError
    end

    protected

    # Maps the platform's language codes to ISO-639-1 hints understood by most
    # providers. Roman Urdu is transcribed as Urdu (script/romanization is a
    # downstream concern); unknown codes fall through to nil (auto-detect).
    ISO_LANGUAGE_HINTS = {
      "english" => "en",
      "urdu" => "ur",
      "roman_urdu" => "ur",
      "punjabi" => "pa"
    }.freeze

    def iso_language(language)
      ISO_LANGUAGE_HINTS[language.to_s]
    end
  end
end
