class VideoBlueprint < Blueprinter::Base
  identifier :id

  fields :project_id, :title, :idea_text, :transcript,
         :language, :tone, :duration_seconds, :status, :active_prompt_id

  # Whether a spoken idea has been uploaded. The storage key itself is never
  # exposed to clients.
  field :has_audio do |video|
    video.audio_attached?
  end

  # Whether a usable idea (typed or transcribed) exists. Named `idea_present` to
  # avoid confusion with the `idea_ready` status enum value.
  field :idea_present do |video|
    video.idea_present?
  end

  field :transcription_failure_reason

  field :created_at do |video|
    video.created_at.iso8601
  end

  field :updated_at do |video|
    video.updated_at.iso8601
  end

  # Full status history, included only when explicitly requested (detail view).
  view :with_history do
    association :status_changes, blueprint: VideoStatusChangeBlueprint
  end
end
