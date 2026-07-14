class ProjectBlueprint < Blueprinter::Base
  identifier :id

  fields :user_id, :name, :slug, :description,
         :default_language, :default_tone, :target_platforms,
         :status, :active_character_id

  field :archived_at do |project|
    project.archived_at&.iso8601
  end

  field :created_at do |project|
    project.created_at.iso8601
  end

  field :updated_at do |project|
    project.updated_at.iso8601
  end

  # Full status history, included only when explicitly requested (detail view).
  view :with_history do
    association :status_changes, blueprint: ProjectStatusChangeBlueprint
  end
end
