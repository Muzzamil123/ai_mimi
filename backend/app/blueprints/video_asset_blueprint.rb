class VideoAssetBlueprint < Blueprinter::Base
  identifier :id

  fields :video_generation_id, :filename, :mime_type, :width, :height,
         :duration_seconds, :file_size, :validation_status

  field :aspect_ratio do |asset|
    asset.video_generation.aspect_ratio
  end

  field :variation_number do |asset|
    asset.video_generation.variation_number
  end

  field :ready do |asset|
    asset.ready?
  end

  field :duplicate do |asset|
    asset.duplicate?
  end

  # Freshly-signed, short-lived URLs (nil until the asset is ready). Re-rendering
  # (re-fetching the list) mints new URLs — this is the "signed URL refresh".
  # Storage keys are never exposed.
  field :stream_url do |asset|
    asset.ready? ? Downloads::SignedUrl.asset_path(asset, disposition: "inline") : nil
  end

  field :download_url do |asset|
    asset.ready? ? Downloads::SignedUrl.asset_path(asset, disposition: "attachment") : nil
  end

  field :thumbnail_url do |asset|
    asset.ready? && asset.thumbnail? ? Downloads::SignedUrl.thumbnail_path(asset) : nil
  end

  field :created_at do |asset|
    asset.created_at.iso8601
  end
end
