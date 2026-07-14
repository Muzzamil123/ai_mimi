# Immutable audit record of a project's status transition.
class ProjectStatusChange < ApplicationRecord
  belongs_to :project
  belongs_to :actor, class_name: "User", optional: true

  validates :to_status, presence: true
end
