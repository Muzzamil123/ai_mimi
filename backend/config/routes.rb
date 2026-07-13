require "sidekiq/web"

Rails.application.routes.draw do
  # Liveness probe (boots with no exceptions) for load balancers.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Deep health check: API, database, Redis, and Sidekiq connectivity.
      get "health", to: "health#show"

      # --- Authentication ---
      namespace :auth do
        post "register", to: "registrations#create"
        post "login", to: "sessions#create"
        post "logout", to: "sessions#destroy"
        post "refresh", to: "tokens#create"
        post "password/forgot", to: "passwords#forgot"
        post "password/reset", to: "passwords#reset"
        post "email/verify", to: "email_verifications#create"
      end

      # --- Current account ---
      get "me", to: "current_user#show"
      patch "me", to: "current_user#update"
      delete "me", to: "current_user#destroy"

      # --- Admin (RBAC; full portal in Phase 11) ---
      namespace :admin do
        resources :users, only: [:index]
      end
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
