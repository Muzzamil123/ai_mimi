# Builds a ZIP of all a project's ready outputs and stores it at a deterministic
# key, so the client can poll for it and download via a signed URL (see
# ProjectArchivesController). Async because a project archive can be large; the
# per-video "download all" builds synchronously.
class BuildProjectDownloadArchiveJob < ApplicationJob
  queue_as :ai_generation

  # Deterministic per-project location (overwritten on each rebuild).
  def self.storage_key(project_id)
    "archives/projects/#{project_id}/latest.zip"
  end

  def perform(project_id)
    project = Project.find_by(id: project_id)
    return if project.nil?

    assets = project.video_assets.select(&:ready?)
    key = self.class.storage_key(project_id)
    VideoAssets::BuildArchive.new(assets).store_to(key)

    Rails.logger.info(message: "project_archive_built", project_id: project_id,
                      storage_key: key, asset_count: assets.size)
    key
  end
end
