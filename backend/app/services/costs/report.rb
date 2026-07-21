module Costs
  # Aggregates the ProviderUsage ledger into the admin cost-dashboard payload:
  # totals, spend by provider/service, a daily trend, and average cost per video
  # and per project. All figures are scoped to the [from, to] window.
  class Report < ApplicationService
    def initialize(from: 30.days.ago.beginning_of_day, to: Time.current.end_of_day)
      @from = from
      @to = to
      @scope = ProviderUsage.in_period(@from..@to)
    end

    def call
      {
        range: { from: @from.iso8601, to: @to.iso8601 },
        totals: totals,
        by_provider: grouped(:provider),
        by_service: grouped(:service_type),
        by_day: by_day,
        averages: averages
      }
    end

    private

    def totals
      {
        estimated_cost: @scope.sum(:estimated_cost).to_f,
        count: @scope.count,
        unpriced_count: @scope.where("metadata->>'pricing_source' = ?", "unpriced").count
      }
    end

    # [{ key:, estimated_cost:, count: }, ...] sorted by spend desc.
    def grouped(column)
      costs = @scope.group(column).sum(:estimated_cost)
      counts = @scope.group(column).count
      costs.map { |key, cost| { key: key, estimated_cost: cost.to_f, count: counts[key].to_i } }
           .sort_by { |row| -row[:estimated_cost] }
    end

    def by_day
      costs = @scope.group(Arel.sql("DATE(occurred_at)")).sum(:estimated_cost)
      costs.map { |day, cost| { day: day.to_s, estimated_cost: cost.to_f } }.sort_by { |row| row[:day] }
    end

    def averages
      video_cost = @scope.where(service_type: "video_generation").sum(:estimated_cost)
      video_count = @scope.where(service_type: "video_generation").distinct.count(:video_id)
      project_cost = @scope.sum(:estimated_cost)
      project_count = @scope.distinct.count(:project_id)

      {
        per_video: video_count.zero? ? 0.0 : (video_cost / video_count).to_f.round(6),
        per_project: project_count.zero? ? 0.0 : (project_cost / project_count).to_f.round(6)
      }
    end
  end
end
