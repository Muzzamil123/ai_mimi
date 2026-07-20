module Api
  module V1
    # A video's downloaded output files (Phase 9). Read + download-all; the
    # per-asset download/playback happens through public signed URLs
    # (DownloadsController). Access is gated by the owning project scope
    # (non-owners get 404).
    class VideoAssetsController < BaseController
      before_action :set_video

      # GET /projects/:project_id/videos/:video_id/assets
      def index
        assets = @video.video_assets.includes(:video_generation).order("video_generations.aspect_ratio",
                                                                       "video_generations.variation_number")
        render json: { video_assets: VideoAssetBlueprint.render_as_hash(assets) }
      end

      # GET /projects/:project_id/videos/:video_id/assets/archive
      # Synchronous "download all outputs" — streams a ZIP of the video's ready
      # assets.
      def archive
        assets = @video.video_assets.select(&:ready?)
        if assets.empty?
          raise ::Videos::InvalidState, "There are no completed outputs to download yet"
        end

        data = ::VideoAssets::BuildArchive.call(assets)
        send_data data, type: "application/zip", disposition: "attachment",
                        filename: "video-#{@video.id}-outputs.zip"
      end

      private

      def set_video
        project = policy_scope(Project).find(params[:project_id])
        @video = project.videos.find(params[:video_id])
      end
    end
  end
end
