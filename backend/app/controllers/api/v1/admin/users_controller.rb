module Api
  module V1
    module Admin
      # Admin account management: list/inspect users and suspend/reactivate them.
      class UsersController < BaseController
        before_action :set_user, only: %i[show suspend reactivate]

        # GET /api/v1/admin/users?q=&role=&status=&page=&per_page=
        def index
          # Correlated subquery (not a GROUP BY) so offset pagination's
          # count(:all) stays a scalar and there is no per-user N+1.
          scope = User.select(
            "users.*, (SELECT COUNT(*) FROM projects WHERE projects.user_id = users.id) AS projects_count"
          ).order(created_at: :desc)
          scope = scope.where(role: params[:role]) if User.roles.key?(params[:role])
          scope = scope.where(status: params[:status]) if User.statuses.key?(params[:status])
          scope = apply_search(scope)

          records, meta = paginate(scope)
          render json: { users: AdminUserBlueprint.render_as_hash(records), meta: meta }
        end

        # GET /api/v1/admin/users/:id
        def show
          render json: AdminUserBlueprint.render_as_hash(@user)
        end

        # POST /api/v1/admin/users/:id/suspend
        def suspend
          ::Admin::SuspendUser.call(@user, actor: current_user)
          audit!("user.suspend", resource: @user, metadata: { reason: params[:reason] }.compact)
          render json: AdminUserBlueprint.render_as_hash(@user.reload)
        end

        # POST /api/v1/admin/users/:id/reactivate
        def reactivate
          ::Admin::ReactivateUser.call(@user, actor: current_user)
          audit!("user.reactivate", resource: @user)
          render json: AdminUserBlueprint.render_as_hash(@user.reload)
        end

        private

        def set_user
          @user = User.find(params[:id])
        end

        def apply_search(scope)
          return scope if params[:q].blank?

          term = "%#{User.sanitize_sql_like(params[:q])}%"
          scope.where("users.email ILIKE :t OR users.name ILIKE :t", t: term)
        end
      end
    end
  end
end
