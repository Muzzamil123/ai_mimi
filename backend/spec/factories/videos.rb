require "securerandom"

FactoryBot.define do
  factory :video do
    association :project, factory: %i[project ready]
    sequence(:title) { |n| "Video #{n}" }
    language { "english" }
    tone { "neutral" }
    duration_seconds { 15 }
    status { :draft }

    trait :with_idea do
      idea_text { "A short clip introducing the mascot to new followers." }
      status { :idea_ready }
    end

    trait :transcribing do
      status { :transcribing }
      transcription_id { SecureRandom.uuid }
      idea_audio_storage_key { "videos/idea-audio/#{SecureRandom.hex(8)}.webm" }
    end

    trait :transcribed do
      status { :idea_ready }
      transcription_id { SecureRandom.uuid }
      idea_audio_storage_key { "videos/idea-audio/#{SecureRandom.hex(8)}.webm" }
      transcript { "This is a transcribed idea." }
      transcription_provider { "fake" }
      transcription_provider_model { "fake-transcribe-1" }
    end

    trait :failed do
      status { :failed }
      transcription_id { SecureRandom.uuid }
      transcription_failure_reason { "provider exploded" }
    end
  end
end
