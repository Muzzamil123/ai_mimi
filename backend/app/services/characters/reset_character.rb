module Characters
  # Administrative reset of a character, including an approved (locked) one. This
  # is the only path out of the approved state. Delegates to the model's audited
  # reset (which records the project status change) and requires an admin actor.
  class ResetCharacter < ApplicationService
    def initialize(character, actor:, reason: "reset by administrator")
      @character = character
      @actor = actor
      @reason = reason
    end

    def call
      unless @actor&.admin?
        raise Characters::InvalidState, "Only an administrator may reset a character"
      end

      @character.reset_by_admin!(actor: @actor, reason: @reason)
      @character
    end
  end
end
