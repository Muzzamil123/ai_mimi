module Api
  module V1
    module Admin
      # Platform configuration. `index` returns the full registry snapshot with
      # secret values masked (never echoed after saving). `update` upserts one or
      # more known settings and audits which keys changed — never the values,
      # since some are secrets.
      class SettingsController < BaseController
        # GET /api/v1/admin/settings
        def index
          render json: { settings: PlatformSetting.snapshot }
        end

        # PATCH /api/v1/admin/settings  ({ settings: { key => value, ... } })
        def update
          changes = params.require(:settings).to_unsafe_h
          changed_keys = ::Admin::UpdateSettings.call(changes)
          audit!("settings.update", resource: "PlatformSetting", metadata: { keys: changed_keys })
          render json: { settings: PlatformSetting.snapshot }
        end
      end
    end
  end
end
