class BudgetPolicyBlueprint < Blueprinter::Base
  identifier :id

  fields :scope_type, :scope_id, :provider, :warning_percentage, :action_on_limit, :enabled

  field :daily_limit do |policy|
    policy.daily_limit&.to_f
  end

  field :monthly_limit do |policy|
    policy.monthly_limit&.to_f
  end

  field :created_at do |policy|
    policy.created_at.iso8601
  end

  field :updated_at do |policy|
    policy.updated_at.iso8601
  end
end
