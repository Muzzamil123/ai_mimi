module Api
  module V1
    # A video's four generation outputs (Phase 8). All business logic lives in
    # VideoGenerations::* service objects; the controller only authorizes,
    # delegates, and renders. Nested under a project's video.
    class VideoGenerationsController < BaseController
      before_action :set_video
      before_action :set_generation, only: :retry

      # GET /projects/:project_id/videos/:video_id/generations
      # The current batch (outputs for the video's approved prompt).
      def index
        scope = @video.video_generations
        scope = scope.where(prompt_id: @video.active_prompt_id) if @video.active_prompt_id
        scope = scope.order(:aspect_ratio, :variation_number)
        render json: { video_generations: VideoGenerationBlueprint.render_as_hash(scope) }
      end

      # POST /projects/:project_id/videos/:video_id/generations  (start the batch)
      def create
        authorize VideoGeneration.new(video_id: @video.id), :create?
        ::VideoGenerations::StartGeneration.call(@video, actor: current_user)
        render json: batch_payload, status: :accepted
      end

      # POST /projects/:project_id/videos/:video_id/generations/:id/retry
      def retry
        authorize @generation, :retry?
        ::VideoGenerations::RetryGeneration.call(@generation, actor: current_user)
        render json: VideoGenerationBlueprint.render_as_hash(@generation.reload), status: :accepted
      end

      # POST /projects/:project_id/videos/:video_id/generations/cancel
      def cancel
        authorize VideoGeneration.new(video_id: @video.id), :cancel?
        ::VideoGenerations::CancelGeneration.call(@video, actor: current_user)
        render json: batch_payload
      end

      private

      def set_video
        project = policy_scope(Project).find(params[:project_id])
        @video = project.videos.find(params[:video_id])
      end

      def set_generation
        @generation = @video.video_generations.find(params[:id])
      end

      def batch_payload
        scope = @video.video_generations
        scope = scope.where(prompt_id: @video.active_prompt_id) if @video.active_prompt_id
        { video_generations: VideoGenerationBlueprint.render_as_hash(scope.order(:aspect_ratio, :variation_number)) }
      end
    end
  end
end
