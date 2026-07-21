class CreateBudgetPolicies < ActiveRecord::Migration[7.1]
  def change
    # Spend guardrails (Phase 12). A policy applies to a scope (the whole
    # platform, one user, or one project), optionally narrowed to a single
    # provider, and sets a daily and/or monthly limit. When usage in the period
    # reaches warning_percentage a warning is surfaced; when it would exceed a
    # limit the action is either `warn` (soft) or `block` (hard).
    create_table :budget_policies do |t|
      t.string :scope_type, null: false # global | user | project
      t.bigint :scope_id                 # null for global
      t.string :provider                 # null = all providers

      t.decimal :daily_limit, precision: 14, scale: 6
      t.decimal :monthly_limit, precision: 14, scale: 6
      t.integer :warning_percentage, null: false, default: 80
      t.string :action_on_limit, null: false, default: "warn" # warn | block
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end

    add_index :budget_policies, %i[scope_type scope_id]
    add_index :budget_policies, :enabled
  end
end
