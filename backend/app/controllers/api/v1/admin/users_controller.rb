module Api
  module V1
    module Admin
      # GET /api/v1/admin/users — admin-only listing (full admin portal is Phase 11).
      class UsersController < BaseController
        def index
          authorize User, :index?
          users = User.order(created_at: :desc).limit(100)
          render json: UserBlueprint.render_as_hash(users)
        end
      end
    end
  end
end
