# The downloaded, validated, permanently stored file for one generation output.
# Exactly one per VideoGeneration. Ready to serve once validated AND stored.
class VideoAsset < ApplicationRecord
  belongs_to :video_generation
  # A deduped asset shares the original's stored file (same storage_key), so any
  # future "delete stored file on destroy" must not remove a file still shared by
  # a duplicate or its original. The FK is nullify, so losing the original keeps
  # this row (and its storage_key) intact.
  belongs_to :duplicate_of, class_name: "VideoAsset", optional: true
  has_one :video, through: :video_generation
  has_one :project, through: :video_generation

  enum :validation_status, {
    pending: 0,
    valid: 1,
    invalid: 2,
    failed: 3
  }, default: :pending, prefix: :validation

  # Available to download/play: validated and permanently stored.
  def ready?
    validation_valid? && stored_at.present?
  end

  def thumbnail?
    thumbnail_storage_key.present?
  end

  def duplicate?
    duplicate_of_id.present?
  end
end
