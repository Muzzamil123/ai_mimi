module Api
  module V1
    # Videos are a plural nested resource: a ready project owns many videos
    # (Phase 6). All business logic lives in Videos::* service objects; the
    # controller only authorizes, delegates, and renders.
    class VideosController < BaseController
      include Paginatable

      before_action :set_project
      before_action :set_video, only: %i[show update destroy upload_audio]

      # GET /projects/:project_id/videos?q=&status=&page=&per_page=
      def index
        scope = policy_scope(Video).where(project_id: @project.id)
        scope = scope.where(status: params[:status]) if Video.statuses.key?(params[:status])
        scope = scope.search(params[:q]) if params[:q].present?
        scope = scope.order(created_at: :desc)

        records, meta = paginate(scope)
        render json: { videos: VideoBlueprint.render_as_hash(records), meta: meta }
      end

      # GET /projects/:project_id/videos/:id
      def show
        render json: VideoBlueprint.render_as_hash(@video, view: :with_history)
      end

      # POST /projects/:project_id/videos
      def create
        # Authorize via project_id (not `project:`) so we don't populate the
        # project's in-memory has_many :videos with an unsaved record.
        authorize Video.new(project_id: @project.id), :create?
        video = ::Videos::CreateVideo.call(@project, video_params, actor: current_user)
        render json: VideoBlueprint.render_as_hash(video), status: :created
      end

      # PATCH /projects/:project_id/videos/:id  (edit idea / transcript)
      def update
        authorize @video, :update?
        ::Videos::UpdateVideoIdea.call(@video, video_params, actor: current_user)
        render json: VideoBlueprint.render_as_hash(@video.reload, view: :with_history)
      end

      # DELETE /projects/:project_id/videos/:id  (drafts only)
      def destroy
        authorize @video, :destroy?
        ::Videos::DeleteVideo.call(@video)
        head :no_content
      end

      # POST /projects/:project_id/videos/:id/audio  (multipart spoken idea)
      def upload_audio
        authorize @video, :upload_audio?
        ::Videos::UploadAudio.call(@video, file: params[:audio], actor: current_user)
        render json: VideoBlueprint.render_as_hash(@video.reload, view: :with_history), status: :accepted
      end

      private

      # Scoped find: non-owners get 404 (no existence leak); admins see all.
      def set_project
        @project = policy_scope(Project).find(params[:project_id])
      end

      def set_video
        @video = @project.videos.find(params[:id])
      end

      def video_params
        params.require(:video).permit(:title, :idea_text, :transcript, :language, :tone, :duration_seconds)
      end
    end
  end
end
