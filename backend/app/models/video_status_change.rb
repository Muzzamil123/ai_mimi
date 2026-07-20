# Immutable audit record of a video's status transition.
class VideoStatusChange < ApplicationRecord
  belongs_to :video
  belongs_to :actor, class_name: "User", optional: true

  validates :to_status, presence: true
end
