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

      # Liveness: the process is up and serving. No dependency checks, so an
      # orchestrator never restarts a healthy pod just because a dependency
      # blips. Always 200.
      def live
        render json: { status: "ok" }
      end

      # Readiness: can this instance serve traffic right now? Checks the
      # datastores the API needs (database + Redis). 503 keeps it out of the
      # load-balancer pool until dependencies recover.
      def ready
        components = Health::CheckService.call.components.slice(:database, :redis)
        ready = components.values.all? { |value| value == Health::Report::OK }
        render json: { status: ready ? "ready" : "not_ready", components: components },
               status: ready ? :ok : :service_unavailable
      end
    end
  end
end
