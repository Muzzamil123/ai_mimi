class VideoGenerationBlueprint < Blueprinter::Base
  identifier :id

  fields :video_id, :aspect_ratio, :variation_number, :duration_seconds,
         :status, :progress, :attempt_count, :error_code, :error_message,
         :provider

  field :label do |generation|
    generation.label
  end

  field :estimated_cost do |generation|
    generation.estimated_cost&.to_f
  end

  field :started_at do |generation|
    generation.started_at&.iso8601
  end

  field :completed_at do |generation|
    generation.completed_at&.iso8601
  end

  field :created_at do |generation|
    generation.created_at.iso8601
  end
end
