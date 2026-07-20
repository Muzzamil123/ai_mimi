module Api
  module V1
    # A video owns many prompt versions (Phase 7). All business logic lives in
    # Prompts::* service objects; the controller only authorizes, delegates, and
    # renders. Nested under a project's video.
    class PromptsController < BaseController
      include Paginatable

      before_action :set_video
      before_action :set_prompt, only: %i[show approve]

      # GET /projects/:project_id/videos/:video_id/prompts  (version history)
      def index
        scope = @video.prompts.by_version
        records, meta = paginate(scope)
        render json: { prompts: PromptBlueprint.render_as_hash(records), meta: meta }
      end

      # GET /projects/:project_id/videos/:video_id/prompts/:id
      def show
        render json: PromptBlueprint.render_as_hash(@prompt)
      end

      # POST /projects/:project_id/videos/:video_id/prompts
      # Saves a manually edited prompt as a new draft version.
      def create
        authorize Prompt.new(video_id: @video.id), :create?
        prompt = ::Prompts::SavePromptVersion.call(@video, content: prompt_params[:content], actor: current_user)
        render json: PromptBlueprint.render_as_hash(prompt), status: :created
      end

      # POST /projects/:project_id/videos/:video_id/prompts/generate
      # Starts async AI generation of a new prompt version (initial or regenerate).
      def generate
        authorize Prompt.new(video_id: @video.id), :generate?
        prompt = ::Prompts::GeneratePrompt.call(@video, actor: current_user)
        render json: PromptBlueprint.render_as_hash(prompt), status: :accepted
      end

      # POST /projects/:project_id/videos/:video_id/prompts/:id/approve
      def approve
        authorize @prompt, :approve?
        ::Prompts::ApprovePrompt.call(@prompt, actor: current_user)
        render json: PromptBlueprint.render_as_hash(@prompt.reload)
      end

      private

      # Scoped find: non-owners get 404 (no existence leak); admins see all.
      def set_video
        project = policy_scope(Project).find(params[:project_id])
        @video = project.videos.find(params[:video_id])
      end

      def set_prompt
        @prompt = @video.prompts.find(params[:id])
      end

      def prompt_params
        params.require(:prompt).permit(:content)
      end
    end
  end
end
