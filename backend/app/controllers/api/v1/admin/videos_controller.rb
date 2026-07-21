module Api
  module V1
    module Admin
      # Video explorer + prompt-generation retry. Admins see all videos.
      class VideosController < BaseController
        before_action :set_video, only: %i[show retry_prompt]

        # GET /api/v1/admin/videos?project_id=&status=&q=&page=&per_page=
        def index
          scope = Video.includes(:project).order(created_at: :desc)
          scope = scope.where(status: params[:status]) if Video.statuses.key?(params[:status])
          scope = scope.where(project_id: params[:project_id]) if params[:project_id].present?
          scope = apply_search(scope)

          records, meta = paginate(scope)
          render json: { videos: VideoBlueprint.render_as_hash(records), meta: meta }
        end

        # GET /api/v1/admin/videos/:id
        def show
          render json: {
            video: VideoBlueprint.render_as_hash(@video, view: :with_history),
            prompts: PromptBlueprint.render_as_hash(@video.prompts.order(version: :desc)),
            generations: VideoGenerationBlueprint.render_as_hash(
              @video.video_generations.order(created_at: :desc)
            )
          }
        end

        # POST /api/v1/admin/videos/:id/retry_prompt
        def retry_prompt
          ::Prompts::GeneratePrompt.call(@video, actor: current_user)
          audit!("prompt.retry_generation", resource: @video)
          render json: VideoBlueprint.render_as_hash(@video.reload)
        end

        private

        def set_video
          @video = Video.find(params[:id])
        end

        def apply_search(scope)
          return scope if params[:q].blank?

          scope.where("videos.title ILIKE ?", "%#{Video.sanitize_sql_like(params[:q])}%")
        end
      end
    end
  end
end
