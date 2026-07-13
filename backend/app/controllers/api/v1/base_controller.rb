module Api
  module V1
    # Base controller for all versioned API endpoints. Cross-cutting concerns
    # (authentication, authorization, error rendering, pagination) are added
    # here in later phases so individual controllers stay thin.
    class BaseController < ApplicationController
    end
  end
end
