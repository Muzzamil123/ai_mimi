# Step 4: promote the validated file to its permanent location and mark the asset
# stored (ready to serve).
class StoreGeneratedVideoJob < VideoAssets::ProcessingJob
  def perform(asset_id)
    process_step(asset_id) do |asset|
      VideoAssets::Store.call(asset)
    end
  end
end
