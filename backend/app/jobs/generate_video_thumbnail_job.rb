# Step 3: generate and store the poster thumbnail, then hand off to permanent
# storage.
class GenerateVideoThumbnailJob < VideoAssets::ProcessingJob
  def perform(asset_id)
    process_step(asset_id) do |asset|
      VideoAssets::GenerateThumbnail.call(asset)
      StoreGeneratedVideoJob.perform_later(asset.id)
    end
  end
end
