module Projects
  # Archives a project (from any non-archived status). Raises InvalidTransition
  # if the project is already archived.
  class ArchiveProject < ApplicationService
    def initialize(project, actor: nil)
      @project = project
      @actor = actor
    end

    def call
      @project.transition_to!(:archived, actor: @actor, reason: "archived by owner")
      @project
    end
  end
end
