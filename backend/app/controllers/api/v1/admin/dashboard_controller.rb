module Api
  module V1
    module Admin
      # Operational overview for the admin landing page: counts by status across
      # the core resources, plus a live infrastructure health snapshot. Read-only.
      class DashboardController < BaseController
        def show
          render json: {
            users: User.group(:status).count,
            projects: Project.group(:status).count,
            videos: Video.group(:status).count,
            generations: VideoGeneration.group(:status).count,
            assets: VideoAsset.group(:validation_status).count,
            email_deliveries: EmailDelivery.group(:status).count,
            totals: {
              users: User.count,
              projects: Project.count,
              videos: Video.count,
              generations: VideoGeneration.count,
              failed_generations: VideoGeneration.failed.count,
              audit_logs: AuditLog.count
            },
            health: HealthBlueprint.render_as_hash(Health::CheckService.call)
          }
        end
      end
    end
  end
end
