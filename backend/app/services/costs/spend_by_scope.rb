module Costs
  # Spend grouped by user or by project over a window — the data behind the admin
  # "user spend" and "project spend" tables. Returns rows ordered by spend desc,
  # each with the owner's/project's display label resolved in a single follow-up
  # query (no N+1). Rows with a null grouping key (unattributed usage) are dropped.
  class SpendByScope < ApplicationService
    GROUPS = { user: :user_id, project: :project_id }.freeze

    def initialize(group:, from: 30.days.ago.beginning_of_day, to: Time.current.end_of_day, limit: 50)
      @column = GROUPS.fetch(group.to_sym) { raise ArgumentError, "Unknown spend group: #{group}" }
      @group = group.to_sym
      @from = from
      @to = to
      @limit = limit.to_i.clamp(1, 200)
    end

    def call
      scope = ProviderUsage.in_period(@from..@to).where.not(@column => nil)
      costs = scope.group(@column).sum(:estimated_cost)
      counts = scope.group(@column).count

      rows = costs.map { |id, cost| { id: id, estimated_cost: cost.to_f, count: counts[id].to_i } }
                  .sort_by { |row| -row[:estimated_cost] }
                  .first(@limit)

      attach_labels(rows)
    end

    private

    def attach_labels(rows)
      ids = rows.map { |row| row[:id] }
      labels =
        if @group == :user
          User.where(id: ids).pluck(:id, :email).to_h
        else
          Project.where(id: ids).pluck(:id, :name).to_h
        end
      rows.each { |row| row[:label] = labels[row[:id]] }
      rows
    end
  end
end
