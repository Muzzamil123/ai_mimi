module Api
  module V1
    module Admin
      # Read-only audit trail with filtering by action, actor, and resource.
      class AuditLogsController < BaseController
        # GET /api/v1/admin/audit_logs?action_name=&actor_id=&resource_type=&resource_id=&page=&per_page=
        # (filter param is `action_name`; `action` is reserved by Rails routing.)
        def index
          scope = AuditLog.includes(:actor).recent
          scope = scope.for_action(params[:action_name])
          scope = scope.for_resource(params[:resource_type], params[:resource_id])
          scope = scope.where(actor_type: "User", actor_id: params[:actor_id]) if params[:actor_id].present?

          records, meta = paginate(scope)
          render json: { audit_logs: AuditLogBlueprint.render_as_hash(records), meta: meta }
        end
      end
    end
  end
end
