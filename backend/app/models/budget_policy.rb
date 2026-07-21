# A spend guardrail evaluated by Budgets::Evaluate. Scoped to the whole platform
# (global), a single user, or a single project, and optionally narrowed to one
# provider. A `warn` policy only surfaces a warning; a `block` policy (a hard
# limit) prevents the action that would exceed it (admins may override).
class BudgetPolicy < ApplicationRecord
  SCOPES = %w[global user project].freeze
  ACTIONS = %w[warn block].freeze

  validates :scope_type, inclusion: { in: SCOPES }
  validates :action_on_limit, inclusion: { in: ACTIONS }
  validates :warning_percentage, numericality: { in: 0..100 }
  validates :scope_id, presence: true, unless: :global?
  validate :at_least_one_limit

  scope :enabled, -> { where(enabled: true) }

  # Policies that apply to a prospective call for the given user/project/provider:
  # the global policy, the user's policy, and the project's policy — each only if
  # it targets all providers or the one in play.
  scope :applicable, lambda { |user:, project:, provider: nil|
    clauses = [ "scope_type = 'global'" ]
    binds = []
    if user
      clauses << "(scope_type = 'user' AND scope_id = ?)"
      binds << user.id
    end
    if project
      clauses << "(scope_type = 'project' AND scope_id = ?)"
      binds << project.id
    end
    enabled
      .where(clauses.join(" OR "), *binds)
      .where("provider IS NULL OR provider = ?", provider)
  }

  def global?
    scope_type == "global"
  end

  def hard?
    action_on_limit == "block"
  end

  private

  def at_least_one_limit
    return if daily_limit.present? || monthly_limit.present?

    errors.add(:base, "Set a daily and/or monthly limit")
  end
end
