module Api
  module V1
    # A project owns exactly one character, so this is a singular nested resource
    # (/projects/:project_id/character). All business logic lives in the
    # Characters::* service objects; the controller only authorizes, delegates,
    # and renders.
    class CharactersController < BaseController
      include StreamsCharacterImage

      before_action :set_project
      before_action :set_character,
                    only: %i[show update destroy generate approve reject reset image]

      # GET /projects/:project_id/character
      def show
        render json: CharacterBlueprint.render_as_hash(@character)
      end

      # POST /projects/:project_id/character
      def create
        # Authorize via project_id (not `project:`) so we don't populate the
        # project's in-memory has_one :character with an unsaved record.
        authorize Character.new(project_id: @project.id), :create?
        character = ::Characters::CreateCharacter.call(@project, character_params, actor: current_user)
        render json: CharacterBlueprint.render_as_hash(character), status: :created
      end

      # PATCH /projects/:project_id/character  (setup edits, pre-generation only)
      def update
        authorize @character, :update?
        unless @character.pending?
          raise ::Characters::InvalidState, "A character can only be edited before generation"
        end

        @character.update!(character_params)
        render json: CharacterBlueprint.render_as_hash(@character)
      end

      # DELETE /projects/:project_id/character
      def destroy
        authorize @character, :destroy?
        if @character.approved?
          raise ::Characters::InvalidState, "An approved character is locked and cannot be deleted"
        end

        @character.destroy!
        head :no_content
      end

      # POST /projects/:project_id/character/generate  (initial or regenerate)
      def generate
        authorize @character, :generate?
        ::Characters::GenerateCharacter.call(@character, actor: current_user)
        render json: CharacterBlueprint.render_as_hash(@character.reload), status: :accepted
      end

      # POST /projects/:project_id/character/approve
      def approve
        authorize @character, :approve?
        ::Characters::ApproveCharacter.call(@character, actor: current_user)
        render json: CharacterBlueprint.render_as_hash(@character.reload)
      end

      # POST /projects/:project_id/character/reject
      def reject
        authorize @character, :reject?
        ::Characters::RejectCharacter.call(@character, feedback: params[:feedback], actor: current_user)
        render json: CharacterBlueprint.render_as_hash(@character.reload)
      end

      # POST /projects/:project_id/character/reset  (admin only)
      def reset
        authorize @character, :reset?
        ::Characters::ResetCharacter.call(@character, actor: current_user)
        render json: CharacterBlueprint.render_as_hash(@character.reload)
      end

      # GET /projects/:project_id/character/image  (authenticated binary stream)
      def image
        authorize @character, :image?
        stream_character_image(@character.latest_image)
      end

      private

      # Scoped find: non-owners get 404 (no existence leak); admins see all.
      def set_project
        @project = policy_scope(Project).find(params[:project_id])
      end

      def set_character
        @character = @project.character
        raise ActiveRecord::RecordNotFound if @character.nil?
      end

      def character_params
        permitted = params.require(:character).permit(
          :name, :description, attributes: {}, style_preferences: {}
        )
        permitted[:character_attributes] = permitted.delete(:attributes) if permitted.key?(:attributes)
        permitted
      end
    end
  end
end
