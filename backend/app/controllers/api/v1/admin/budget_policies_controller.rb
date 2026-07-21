module Api
  module V1
    module Admin
      # CRUD for budget policies (Phase 12). Every change is audited.
      class BudgetPoliciesController < BaseController
        before_action :set_policy, only: %i[update destroy]

        # GET /api/v1/admin/budget_policies
        def index
          policies = BudgetPolicy.order(:scope_type, :scope_id)
          render json: { budget_policies: BudgetPolicyBlueprint.render_as_hash(policies) }
        end

        # POST /api/v1/admin/budget_policies
        def create
          policy = BudgetPolicy.create!(policy_params)
          audit!("budget_policy.create", resource: policy, metadata: policy_context(policy))
          render json: BudgetPolicyBlueprint.render_as_hash(policy), status: :created
        end

        # PATCH /api/v1/admin/budget_policies/:id
        def update
          @policy.update!(policy_params)
          audit!("budget_policy.update", resource: @policy, metadata: policy_context(@policy))
          render json: BudgetPolicyBlueprint.render_as_hash(@policy)
        end

        # DELETE /api/v1/admin/budget_policies/:id
        def destroy
          @policy.destroy!
          audit!("budget_policy.delete", resource: @policy, metadata: policy_context(@policy))
          head :no_content
        end

        private

        def set_policy
          @policy = BudgetPolicy.find(params[:id])
        end

        def policy_params
          params.require(:budget_policy).permit(
            :scope_type, :scope_id, :provider, :daily_limit, :monthly_limit,
            :warning_percentage, :action_on_limit, :enabled
          )
        end

        def policy_context(policy)
          {
            scope_type: policy.scope_type, scope_id: policy.scope_id,
            provider: policy.provider, action_on_limit: policy.action_on_limit
          }
        end
      end
    end
  end
end
