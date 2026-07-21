module Providers
  # Resolves a provider API credential, preferring the admin-managed, encrypted
  # PlatformSetting (Phase 11) and falling back to ENV for backward compatibility
  # and 12-factor deploys. This is the single access point for provider secrets:
  # adapters never read raw ENV, and secrets are never logged or returned to
  # clients. Returns nil when neither source has a value.
  class Credentials
    def self.fetch(setting_key, env: nil)
      setting_key = setting_key.to_s
      stored = PlatformSetting.get(setting_key) if PlatformSetting::KEYS.include?(setting_key)
      return stored if stored.present?

      env ? ENV[env].presence : nil
    end
  end
end
