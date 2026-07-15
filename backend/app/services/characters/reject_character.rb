module Characters
  # Rejects a character awaiting approval, recording the user's feedback so the
  # next generation can incorporate it. Moves the project to `character_rejected`.
  class RejectCharacter < ApplicationService
    def initialize(character, feedback: nil, actor: nil)
      @character = character
      @feedback = feedback
      @actor = actor
    end

    def call
      unless @character.awaiting_approval?
        raise Characters::InvalidState, "Only a character awaiting approval can be rejected"
      end

      @character.update!(rejection_feedback: @feedback.presence)
      @character.transition_to!(:rejected, actor: @actor, reason: "character rejected")
      @character
    end
  end
end
