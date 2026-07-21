module Api
  module V1
    module Admin
      # CRUD for configurable provider pricing (Phase 12). Every change is
      # audited. Editing pricing changes future cost calculations only; recorded
      # ledger rows keep the cost they were computed with.
      class ProviderPricesController < BaseController
        before_action :set_price, only: %i[update destroy]

        # GET /api/v1/admin/provider_prices
        def index
          prices = ProviderPrice.order(:provider, :service_type, :model)
          render json: { provider_prices: ProviderPriceBlueprint.render_as_hash(prices) }
        end

        # POST /api/v1/admin/provider_prices
        def create
          price = ProviderPrice.create!(price_params)
          audit!("provider_price.create", resource: price, metadata: price_context(price))
          render json: ProviderPriceBlueprint.render_as_hash(price), status: :created
        end

        # PATCH /api/v1/admin/provider_prices/:id
        def update
          @price.update!(price_params)
          audit!("provider_price.update", resource: @price, metadata: price_context(@price))
          render json: ProviderPriceBlueprint.render_as_hash(@price)
        end

        # DELETE /api/v1/admin/provider_prices/:id
        def destroy
          @price.destroy!
          audit!("provider_price.delete", resource: @price, metadata: price_context(@price))
          head :no_content
        end

        private

        def set_price
          @price = ProviderPrice.find(params[:id])
        end

        def price_params
          params.require(:provider_price).permit(
            :provider, :service_type, :model, :currency, :enabled,
            *ProviderPrice::RATE_COLUMNS
          )
        end

        def price_context(price)
          { provider: price.provider, service_type: price.service_type, model: price.model }
        end
      end
    end
  end
end
