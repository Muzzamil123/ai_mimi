module Admin
  # Upserts one or more platform settings. Accepts a { key => value } hash;
  # unknown keys are rejected (fail-closed) so a typo never silently no-ops.
  # Returns the list of keys that changed so the caller can audit precisely
  # which settings were touched (values are never audited — some are secret).
  class UpdateSettings < ApplicationService
    def initialize(changes)
      @changes = (changes || {}).to_h.stringify_keys
    end

    def call
      unknown = @changes.keys - PlatformSetting::KEYS
      if unknown.any?
        raise Admin::InvalidOperation, "Unknown setting(s): #{unknown.join(', ')}"
      end

      changed_keys = []
      PlatformSetting.transaction do
        @changes.each do |key, value|
          PlatformSetting.set(key, value)
          changed_keys << key
        end
      end
      changed_keys
    end
  end
end
