module Characters
  # Creates the single character for a project (setup step). The project must
  # still be a draft and must not already own a character. Does not start
  # generation — that is a separate, explicit step (Characters::GenerateCharacter).
  class CreateCharacter < ApplicationService
    def initialize(project, params, actor: nil)
      @project = project
      @params = params
      @actor = actor
    end

    def call
      if @project.character.present?
        raise Characters::InvalidState, "This project already has a character"
      end

      unless @project.draft?
        raise Characters::InvalidState, "A character can only be set up while the project is a draft"
      end

      @project.create_character!(@params)
    end
  end
end
