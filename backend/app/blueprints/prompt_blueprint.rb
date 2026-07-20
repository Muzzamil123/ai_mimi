class PromptBlueprint < Blueprinter::Base
  identifier :id

  fields :video_id, :version, :content, :source_idea,
         :provider, :provider_model, :status,
         :input_tokens, :output_tokens, :created_by_type, :created_by_id,
         :failure_reason

  # Whether this version is the video's active (approved) prompt.
  field :active do |prompt|
    prompt.video.active_prompt_id == prompt.id
  end

  field :estimated_cost do |prompt|
    prompt.estimated_cost&.to_f
  end

  field :created_at do |prompt|
    prompt.created_at.iso8601
  end

  field :updated_at do |prompt|
    prompt.updated_at.iso8601
  end
end
