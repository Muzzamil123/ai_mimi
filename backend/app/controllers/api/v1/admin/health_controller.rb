module Api
  module V1
    module Admin
      # Admin health page: the same infrastructure probe as the public health
      # endpoint, but always behind admin auth and always 200 (the payload
      # carries the status so the page can render a degraded state).
      class HealthController < BaseController
        def show
          render json: HealthBlueprint.render_as_hash(Health::CheckService.call)
        end
      end
    end
  end
end
