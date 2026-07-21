module Api
  module V1
    module Admin
      # Project explorer + operational controls. Admins see every project
      # (no ownership scoping) and can inspect, archive, reset the approved
      # character (audited, with reason), or retry a failed character generation.
      class ProjectsController < BaseController
        before_action :set_project, only: %i[show archive reset_character retry_character]

        # GET /api/v1/admin/projects?q=&status=&user_id=&page=&per_page=
        def index
          scope = Project.includes(:user).order(created_at: :desc)
          scope = scope.where(status: params[:status]) if Project.statuses.key?(params[:status])
          scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?
          scope = scope.search(params[:q]) if params[:q].present?

          records, meta = paginate(scope)
          render json: { projects: ProjectBlueprint.render_as_hash(records), meta: meta }
        end

        # GET /api/v1/admin/projects/:id — full inspection payload.
        def show
          render json: {
            project: ProjectBlueprint.render_as_hash(@project, view: :with_history),
            owner: AdminUserBlueprint.render_as_hash(@project.user),
            character: @project.character && CharacterBlueprint.render_as_hash(@project.character),
            videos: VideoBlueprint.render_as_hash(@project.videos.order(created_at: :desc)),
            generations: VideoGenerationBlueprint.render_as_hash(
              @project.video_generations.order(created_at: :desc)
            )
          }
        end

        # POST /api/v1/admin/projects/:id/archive
        def archive
          ::Projects::ArchiveProject.call(@project, actor: current_user)
          audit!("project.archive", resource: @project)
          render json: ProjectBlueprint.render_as_hash(@project.reload)
        end

        # POST /api/v1/admin/projects/:id/reset_character
        def reset_character
          character = require_character!
          reason = params[:reason].presence || "reset by administrator"
          ::Characters::ResetCharacter.call(character, actor: current_user, reason: reason)
          audit!("character.reset", resource: character, metadata: { project_id: @project.id, reason: reason })
          render json: CharacterBlueprint.render_as_hash(character.reload)
        end

        # POST /api/v1/admin/projects/:id/retry_character
        def retry_character
          character = require_character!
          ::Characters::GenerateCharacter.call(character, actor: current_user)
          audit!("character.retry_generation", resource: character, metadata: { project_id: @project.id })
          render json: CharacterBlueprint.render_as_hash(character.reload)
        end

        private

        def set_project
          @project = Project.find(params[:id])
        end

        def require_character!
          @project.character || raise(::Admin::InvalidOperation, "This project has no character")
        end
      end
    end
  end
end
