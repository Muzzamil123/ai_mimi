module Api
  module V1
    # GET /api/v1/health
    # Reports API status plus database, Redis, and Sidekiq connectivity.
    # Returns 200 when everything is healthy, 503 when any dependency is down.
    class HealthController < BaseController
      skip_authentication

      def show
        report = Health::CheckService.call
        http_status = report.healthy? ? :ok : :service_unavailable

        render json: HealthBlueprint.render_as_hash(report), status: http_status
      end
    end
  end
end
