module Api
  module V1
    module Admin
      # Base for every admin-portal endpoint. Inherits token authentication and
      # the JSON error envelope from the API base controller, then requires an
      # admin role (401 if unauthenticated, 403 if a non-admin). Provides the
      # `audit!` helper so mutating actions record to the audit trail.
      class BaseController < Api::V1::BaseController
        include Auditable
        include Paginatable

        before_action :require_admin!

        rescue_from ::Admin::InvalidOperation do |e|
          render_error(:unprocessable_entity, "invalid_operation", e.message)
        end
      end
    end
  end
end
