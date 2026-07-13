# Serializes a {Health::Report} into the JSON contract consumed by the frontend.
class HealthBlueprint < Blueprinter::Base
  field :status
  field :version
  field :components

  field :timestamp do |report|
    report.checked_at.iso8601
  end
end
