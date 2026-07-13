require "sidekiq/web"

Rails.application.routes.draw do
  # Liveness probe (boots with no exceptions) for load balancers.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Deep health check: API, database, Redis, and Sidekiq connectivity.
      get "health", to: "health#show"
    end
  end

  # Sidekiq dashboard. In development it is open for convenience; in every other
  # environment it requires HTTP Basic credentials until full admin RBAC lands
  # (Phase 11). Never exposed without protection outside development.
  if Rails.env.development?
    mount Sidekiq::Web => "/sidekiq"
  else
    Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
      expected_user = ENV["SIDEKIQ_WEB_USER"].to_s
      expected_password = ENV["SIDEKIQ_WEB_PASSWORD"].to_s
      next false if expected_user.empty? || expected_password.empty?

      ActiveSupport::SecurityUtils.secure_compare(user, expected_user) &
        ActiveSupport::SecurityUtils.secure_compare(password, expected_password)
    end
    mount Sidekiq::Web => "/sidekiq"
  end
end
