module Api
  module V1
    class ProjectsController < BaseController
      include Paginatable

      before_action :set_project, only: %i[show update destroy archive restore]

      # GET /api/v1/projects?q=&status=&page=&per_page=
      def index
        scope = policy_scope(Project)
        scope = scope.where(status: params[:status]) if Project.statuses.key?(params[:status])
        scope = scope.search(params[:q]) if params[:q].present?
        scope = scope.order(created_at: :desc)

        records, meta = paginate(scope)
        render json: { projects: ProjectBlueprint.render_as_hash(records), meta: meta }
      end

      # GET /api/v1/projects/:id
      def show
        render json: ProjectBlueprint.render_as_hash(@project, view: :with_history)
      end

      # POST /api/v1/projects
      def create
        project = ::Projects::CreateProject.call(current_user, project_params)
        render json: ProjectBlueprint.render_as_hash(project), status: :created
      end

      # PATCH /api/v1/projects/:id  (editing allowed only before character setup)
      def update
        unless @project.draft?
          raise ::Projects::InvalidTransition, "Only draft projects can be edited"
        end

        @project.update!(project_params)
        render json: ProjectBlueprint.render_as_hash(@project)
      end

      # DELETE /api/v1/projects/:id  (only drafts are deletable)
      def destroy
        unless @project.draft?
          raise ::Projects::InvalidTransition, "Only draft projects can be deleted"
        end

        @project.destroy!
        head :no_content
      end

      # POST /api/v1/projects/:id/archive
      def archive
        ::Projects::ArchiveProject.call(@project, actor: current_user)
        render json: ProjectBlueprint.render_as_hash(@project)
      end

      # POST /api/v1/projects/:id/restore
      def restore
        ::Projects::RestoreProject.call(@project, actor: current_user)
        render json: ProjectBlueprint.render_as_hash(@project)
      end

      private

      # Scoped find: non-owners get 404 (no existence leak); admins see all.
      def set_project
        @project = policy_scope(Project).find(params[:id])
        authorize @project
      end

      def project_params
        params.require(:project).permit(
          :name, :description, :default_language, :default_tone,
          target_platforms: []
        )
      end
    end
  end
end
