require "sidekiq/web"

Rails.application.routes.draw do
  # Liveness probe (boots with no exceptions) for load balancers.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Deep health check: API, database, Redis, and Sidekiq connectivity.
      get "health", to: "health#show"
      # Kubernetes-style probes: liveness (always 200) and readiness (DB+Redis).
      get "health/live", to: "health#live"
      get "health/ready", to: "health#ready"

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
      get "me/notification_preferences", to: "notification_preferences#show"
      patch "me/notification_preferences", to: "notification_preferences#update"

      # --- Notification center (tracked workflow emails) ---
      resources :notifications, only: %i[index] do
        collection do
          post :read
        end
        member do
          post :retry
        end
      end

      # --- Projects ---
      resources :projects, only: %i[index show create update destroy] do
        member do
          post :archive
          post :restore
          # Async project-wide "download all" archive (Phase 9): POST to build,
          # GET to poll for the signed download URL.
          post :download_archive, to: "project_archives#create"
          get :download_archive, to: "project_archives#show"
        end

        # A project owns exactly one character (singular nested resource).
        resource :character, only: %i[show create update destroy], controller: "characters" do
          post :generate
          post :approve
          post :reject
          post :reset
          get :image
        end

        # A ready project owns many videos (plural nested resource, Phase 6).
        resources :videos, only: %i[index show create update destroy] do
          member do
            post :audio, to: "videos#upload_audio"
          end

          # A video owns many prompt versions (Phase 7).
          resources :prompts, only: %i[index show create] do
            collection do
              post :generate
            end
            member do
              post :approve
            end
          end

          # A video's four generation outputs (Phase 8).
          resources :generations, only: %i[index create], controller: "video_generations" do
            collection do
              post :cancel
              # Pre-generation cost estimate + budget status (Phase 12).
              get :estimate, to: "video_generations#estimate"
            end
            member do
              post :retry
            end
          end

          # A video's downloaded output files (Phase 9).
          resources :assets, only: %i[index], controller: "video_assets" do
            collection do
              get :archive
            end
          end
        end
      end

      # --- Public, token-gated asset/thumbnail/archive downloads (no auth) ---
      get "downloads", to: "downloads#show"

      # --- Provider webhooks (public, signature-verified, no auth) ---
      namespace :webhooks do
        post "video_generations", to: "video_generations#create"
        post "email_deliveries", to: "email_deliveries#create"
      end

      # --- Public character approval (token-protected, no auth) ---
      # Reached from the emailed single-use link; the token is the authorization.
      get    "approvals/character/:token",         to: "approvals#show"
      post   "approvals/character/:token/approve", to: "approvals#approve"
      post   "approvals/character/:token/reject",  to: "approvals#reject"
      get    "approvals/character/:token/image",   to: "approvals#image"

      # --- Admin portal (RBAC + audited operational controls; Phase 11) ---
      namespace :admin do
        get "dashboard", to: "dashboard#show"
        get "health", to: "health#show"

        # Cost tracking, spend tables & usage export (Phase 12).
        get "costs", to: "costs#index"
        get "costs/users", to: "costs#users"
        get "costs/projects", to: "costs#projects"
        get "costs/export", to: "costs#export"
        resources :provider_prices, only: %i[index create update destroy]
        resources :budget_policies, only: %i[index create update destroy]

        get   "settings", to: "settings#index"
        patch "settings", to: "settings#update"

        resources :users, only: %i[index show] do
          member do
            post :suspend
            post :reactivate
          end
        end

        resources :projects, only: %i[index show] do
          member do
            post :archive
            post :reset_character
            post :retry_character
          end
        end

        resources :videos, only: %i[index show] do
          member do
            post :retry_prompt
          end
        end

        resources :video_generations, only: %i[index] do
          member do
            post :retry
            post :retry_asset
            post :cancel
          end
        end

        resources :email_deliveries, only: %i[index] do
          member do
            post :retry
          end
        end

        resources :audit_logs, only: %i[index]
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
