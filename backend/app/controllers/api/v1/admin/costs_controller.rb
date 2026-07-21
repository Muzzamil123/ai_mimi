module Api
  module V1
    module Admin
      # Cost dashboard + spend tables + CSV export, all over the ProviderUsage
      # ledger (Phase 12). Read-only; supersedes the Phase 11 usage stopgap.
      class CostsController < BaseController
        # GET /api/v1/admin/costs?from=&to=
        def index
          render json: ::Costs::Report.call(from: from_date, to: to_date)
        end

        # GET /api/v1/admin/costs/users?from=&to=&limit=
        def users
          render json: { rows: ::Costs::SpendByScope.call(group: :user, from: from_date, to: to_date, limit: limit) }
        end

        # GET /api/v1/admin/costs/projects?from=&to=&limit=
        def projects
          render json: { rows: ::Costs::SpendByScope.call(group: :project, from: from_date, to: to_date, limit: limit) }
        end

        # GET /api/v1/admin/costs/export?from=&to=&provider=  (CSV download)
        def export
          csv = ::Costs::Export.call(from: from_date, to: to_date, provider: params[:provider])
          send_data csv, type: "text/csv", filename: "provider-usage-#{from_date.to_date}-to-#{to_date.to_date}.csv"
        end

        private

        def from_date
          parse_time(params[:from]) || 30.days.ago.beginning_of_day
        end

        def to_date
          parse_time(params[:to]) || Time.current.end_of_day
        end

        def parse_time(value)
          return nil if value.blank?

          Time.zone.parse(value.to_s)
        rescue ArgumentError
          nil
        end

        def limit
          params[:limit].presence || 50
        end
      end
    end
  end
end
