class ProjectStatusChangeBlueprint < Blueprinter::Base
  identifier :id

  fields :from_status, :to_status, :reason, :actor_id

  field :created_at do |change|
    change.created_at.iso8601
  end
end
