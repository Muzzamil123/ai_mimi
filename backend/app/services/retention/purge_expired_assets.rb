module Retention
  # Deletes video assets older than the configured retention window
  # (`file_retention_days` platform setting) and their stored files. A stored
  # blob is removed only when no surviving asset still references the same
  # storage key (deduped assets share a key — Phase 9), so retention never
  # orphans a file that another output still points at. Returns the count purged.
  class PurgeExpiredAssets < ApplicationService
    def initialize(now: Time.current, storage: nil)
      @now = now
      @storage = storage || Storage.adapter
    end

    def call
      days = PlatformSetting.get("file_retention_days").to_i
      return 0 if days <= 0

      cutoff = @now - days.days
      purged = 0

      VideoAsset.where(created_at: ...cutoff).find_each do |asset|
        delete_blob(asset.storage_key, excluding: asset.id)
        delete_blob(asset.thumbnail_storage_key, excluding: asset.id)
        asset.destroy!
        purged += 1
      end
      purged
    end

    private

    # Removes a stored blob unless another asset still references the same key.
    def delete_blob(key, excluding:)
      return if key.blank?
      return if VideoAsset.where(storage_key: key).where.not(id: excluding).exists?
      return if VideoAsset.where(thumbnail_storage_key: key).where.not(id: excluding).exists?

      @storage.delete(key)
    end
  end
end
