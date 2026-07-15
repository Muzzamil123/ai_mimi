module Characters
  # Approves a character awaiting approval: locks it, sets it as the project's
  # active character, and moves the project to `ready`. Only valid from
  # `awaiting_approval`.
  class ApproveCharacter < ApplicationService
    def initialize(character, actor: nil)
      @character = character
      @actor = actor
    end

    def call
      unless @character.awaiting_approval?
        raise Characters::InvalidState, "Only a character awaiting approval can be approved"
      end

      @character.transition_to!(:approved, actor: @actor, reason: "character approved")
      @character
    end
  end
end
