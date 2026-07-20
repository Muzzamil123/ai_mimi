# Step 2: validate the downloaded video (type/playable/duration/aspect). On a
# valid result, hand off to thumbnail generation; an invalid result stops here.
class ValidateGeneratedVideoJob < VideoAssets::ProcessingJob
  def perform(asset_id)
    process_step(asset_id) do |asset|
      VideoAssets::Validate.call(asset)
      GenerateVideoThumbnailJob.perform_later(asset.id) if asset.reload.validation_valid?
    end
  end
end
