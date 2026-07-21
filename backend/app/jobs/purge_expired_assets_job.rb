# Scheduled data-retention sweep (Phase 13): purges video assets past the
# configured retention window. Enqueue periodically (cron / scheduler — see the
# operations runbook); no scheduler gem is bundled yet.
class PurgeExpiredAssetsJob < ApplicationJob
  queue_as :default

  def perform
    count = Retention::PurgeExpiredAssets.call
    Rails.logger.info(message: "retention_purge_completed", purged_assets: count) if count.positive?
    count
  end
end
