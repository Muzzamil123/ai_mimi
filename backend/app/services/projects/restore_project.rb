module Projects
  # Restores an archived project back to the status it held before archiving
  # (defaults to draft). Raises InvalidTransition if the project isn't archived.
  class RestoreProject < ApplicationService
    def initialize(project, actor: nil)
      @project = project
      @actor = actor
    end

    def call
      unless @project.archived?
        raise InvalidTransition, "Only archived projects can be restored"
      end

      @project.transition_to!(previous_status, actor: @actor, reason: "restored by owner")
      @project
    end

    private

    def previous_status
      # reorder (not order) to override the association's default :asc ordering;
      # id breaks ties when two events share a timestamp.
      last_archive = @project.status_changes
                             .where(to_status: "archived")
                             .reorder(created_at: :desc, id: :desc)
                             .first
      last_archive&.from_status.presence || "draft"
    end
  end
end
