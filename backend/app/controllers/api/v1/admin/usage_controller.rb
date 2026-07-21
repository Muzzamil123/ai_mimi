module Api
  module V1
    module Admin
      # Read-only provider-usage summary built from the usage data already
      # recorded on each provider call (character images, prompts, video
      # generations). This is a reporting view over existing records — the
      # dedicated ProviderUsage aggregation, budgets, and limits are Phase 12.
      class UsageController < BaseController
        # GET /api/v1/admin/usage
        def index
          render json: {
            character_generation: summarize(Character.all, service: "character_image"),
            prompt_generation: summarize(Prompt.all, service: "text_generation", tokens: true),
            video_generation: summarize(VideoGeneration.all, service: "video_generation"),
            note: "Aggregated from recorded provider calls. Budgets and limits arrive in Phase 12."
          }
        end

        private

        # A per-provider breakdown plus totals for one billable resource.
        def summarize(relation, service:, tokens: false)
          by_provider = relation.group(:provider).count
          costs = relation.group(:provider).sum(:estimated_cost)

          providers = by_provider.map do |provider, count|
            row = {
              provider: provider,
              count: count,
              estimated_cost: costs.fetch(provider, 0).to_f
            }
            row.merge!(token_totals(relation, provider)) if tokens
            row
          end

          {
            service_type: service,
            total_count: relation.count,
            total_estimated_cost: relation.sum(:estimated_cost).to_f,
            providers: providers
          }
        end

        def token_totals(relation, provider)
          scoped = relation.where(provider: provider)
          {
            input_tokens: scoped.sum(:input_tokens).to_i,
            output_tokens: scoped.sum(:output_tokens).to_i
          }
        end
      end
    end
  end
end
