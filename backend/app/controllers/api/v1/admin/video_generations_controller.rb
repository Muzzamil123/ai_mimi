module Api
  module V1
    module Admin
      # Generation-jobs explorer + operational controls: retry a failed variant,
      # retry its asset processing, or cancel a stuck batch. The default status
      # filter powers the "failed jobs" view. Admins see every generation.
      class VideoGenerationsController < BaseController
        before_action :set_generation, only: %i[retry retry_asset cancel]

        # GET /api/v1/admin/video_generations?status=&project_id=&video_id=&page=&per_page=
        def index
          scope = VideoGeneration.order(created_at: :desc)
          scope = scope.where(status: params[:status]) if VideoGeneration.statuses.key?(params[:status])
          scope = scope.where(project_id: params[:project_id]) if params[:project_id].present?
          scope = scope.where(video_id: params[:video_id]) if params[:video_id].present?

          records, meta = paginate(scope)
          render json: { generations: VideoGenerationBlueprint.render_as_hash(records), meta: meta }
        end

        # POST /api/v1/admin/video_generations/:id/retry — re-run one failed variant.
        def retry
          ::VideoGenerations::RetryGeneration.call(@generation, actor: current_user)
          audit!("video_generation.retry", resource: @generation, metadata: generation_context)
          render json: VideoGenerationBlueprint.render_as_hash(@generation.reload)
        end

        # POST /api/v1/admin/video_generations/:id/retry_asset — re-run download/validation/storage.
        def retry_asset
          ::Admin::RetryAssetProcessing.call(@generation, actor: current_user)
          audit!("video_generation.retry_asset", resource: @generation, metadata: generation_context)
          render json: VideoGenerationBlueprint.render_as_hash(@generation.reload)
        end

        # POST /api/v1/admin/video_generations/:id/cancel — cancel the parent
        # video's active batch (a "stuck job").
        def cancel
          ::VideoGenerations::CancelGeneration.call(@generation.video, actor: current_user)
          audit!("video_generation.cancel", resource: @generation, metadata: generation_context)
          render json: VideoGenerationBlueprint.render_as_hash(@generation.reload)
        end

        private

        def set_generation
          @generation = VideoGeneration.find(params[:id])
        end

        def generation_context
          { video_id: @generation.video_id, project_id: @generation.project_id, label: @generation.label }
        end
      end
    end
  end
end
