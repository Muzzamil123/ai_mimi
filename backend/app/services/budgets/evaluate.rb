require "bigdecimal"

module Budgets
  # Evaluates whether a prospective spend of `prospective_cost` fits within the
  # budget policies applicable to the given user/project/provider. Sums the
  # current day's and month's ledger spend within each policy's scope, compares
  # against its limits, and returns a Budgets::Result. A `block` policy that
  # would be exceeded sets `blocked`; a `warn` policy, or nearing a limit's
  # warning threshold, contributes a warning entry.
  class Evaluate < ApplicationService
    def initialize(user: nil, project: nil, provider: nil, prospective_cost: 0, now: Time.current)
      @user = user
      @project = project
      @provider = provider.presence
      @prospective = BigDecimal(prospective_cost.to_s)
      @now = now
    end

    def call
      entries = []
      blocked = false

      BudgetPolicy.applicable(user: @user, project: @project, provider: @provider).find_each do |policy|
        periods(policy).each do |period, limit, range|
          next if limit.nil?

          spent = spend_for(policy, range)
          projected = spent + @prospective
          limit = BigDecimal(limit.to_s)
          threshold = limit * BigDecimal(policy.warning_percentage.to_s) / 100

          if projected > limit
            blocked ||= policy.hard?
            entries << entry(policy, period, limit, spent, projected, level: "exceeded")
          elsif projected >= threshold
            entries << entry(policy, period, limit, spent, projected, level: "warning")
          end
        end
      end

      Result.new(status: status_for(entries), blocked: blocked, entries: entries)
    end

    private

    def periods(policy)
      [
        [ "daily", policy.daily_limit, @now.beginning_of_day..@now.end_of_day ],
        [ "monthly", policy.monthly_limit, @now.beginning_of_month..@now.end_of_month ]
      ]
    end

    def spend_for(policy, range)
      scope = ProviderUsage.in_period(range)
      scope = scope.where(user_id: policy.scope_id) if policy.scope_type == "user"
      scope = scope.where(project_id: policy.scope_id) if policy.scope_type == "project"
      scope = scope.where(provider: policy.provider) if policy.provider.present?
      BigDecimal(scope.sum(:estimated_cost).to_s)
    end

    def entry(policy, period, limit, spent, projected, level:)
      {
        policy_id: policy.id,
        scope_type: policy.scope_type,
        scope_id: policy.scope_id,
        provider: policy.provider,
        period: period,
        level: level,
        hard: policy.hard?,
        limit: limit.to_f,
        spent: spent.to_f,
        projected: projected.to_f,
        percentage: limit.zero? ? nil : (projected / limit * 100).to_f.round(1)
      }
    end

    def status_for(entries)
      return "exceeded" if entries.any? { |e| e[:level] == "exceeded" }
      return "warning" if entries.any?

      "ok"
    end
  end
end
