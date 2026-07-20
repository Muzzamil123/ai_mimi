module Api
  module V1
    # Project-wide "download all" archive (Phase 9). Building is async (a project
    # can hold many outputs): POST requests a build (202); the client then polls
    # GET, which returns a signed download URL once the archive exists. The
    # per-video download-all is synchronous (VideoAssetsController#archive).
    class ProjectArchivesController < BaseController
      before_action :set_project

      # POST /projects/:id/download_archive
      def create
        BuildProjectDownloadArchiveJob.perform_later(@project.id)
        head :accepted
      end

      # GET /projects/:id/download_archive
      def show
        key = BuildProjectDownloadArchiveJob.storage_key(@project.id)
        if Storage.adapter.exist?(key)
          url = Downloads::SignedUrl.archive_path(key, filename: "project-#{@project.id}-outputs.zip")
          render json: { status: "ready", download_url: url }
        else
          render json: { status: "pending" }, status: :accepted
        end
      end

      private

      # Member route param is :id.
      def set_project
        @project = policy_scope(Project).find(params[:id])
      end
    end
  end
end
