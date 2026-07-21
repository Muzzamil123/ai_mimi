# A single admin-managed platform configuration value (Phase 11). Only keys in
# REGISTRY are permitted; each entry declares a type, whether it is a secret,
# a default, and a human description. Values are encrypted at rest; secret
# values are never echoed back through the API (see PlatformSettingBlueprint).
#
# Runtime note: provider adapters still read credentials from ENV. These records
# are the admin-facing configuration of record and operational controls (e.g.
# maintenance_mode, email sender identity are consumed live). Unifying provider
# credentials onto encrypted settings is Phase 13 (secret storage) work.
class PlatformSetting < ApplicationRecord
  encrypts :value

  # key => { type:, secret:, default:, description: }
  REGISTRY = {
    "maintenance_mode" => {
      type: :boolean, secret: false, default: false,
      description: "When enabled, non-admin write requests are rejected with 503."
    },
    "email_sender_name" => {
      type: :string, secret: false, default: "AI Video Platform",
      description: "Display name used for outbound platform emails."
    },
    "email_from_address" => {
      type: :string, secret: false, default: nil,
      description: "From address for outbound platform emails (blank = mailer default)."
    },
    "text_generation_provider" => {
      type: :string, secret: false, default: nil,
      description: "Active text/prompt provider adapter (OpenAI). Blank = ENV default."
    },
    "character_image_provider" => {
      type: :string, secret: false, default: nil,
      description: "Active character-image provider adapter (Gemini). Blank = ENV default."
    },
    "video_generation_provider" => {
      type: :string, secret: false, default: nil,
      description: "Active video provider adapter (Google Labs). Blank = ENV default."
    },
    "openai_api_key" => {
      type: :string, secret: true, default: nil,
      description: "OpenAI API credential (prompts/transcription)."
    },
    "gemini_api_key" => {
      type: :string, secret: true, default: nil,
      description: "Google Gemini API credential (character images)."
    },
    "google_labs_api_key" => {
      type: :string, secret: true, default: nil,
      description: "Google Labs API credential (video generation)."
    },
    "generation_timeout_seconds" => {
      type: :integer, secret: false, default: 600,
      description: "Provider generation timeout in seconds."
    },
    "generation_retry_count" => {
      type: :integer, secret: false, default: 5,
      description: "Maximum retry attempts for a transient provider failure."
    },
    "file_retention_days" => {
      type: :integer, secret: false, default: 90,
      description: "Days generated assets are retained before cleanup."
    }
  }.freeze

  KEYS = REGISTRY.keys.freeze

  validates :key, presence: true, uniqueness: true, inclusion: { in: KEYS }

  class << self
    def registry_entry(key)
      REGISTRY.fetch(key.to_s) { raise ArgumentError, "Unknown platform setting: #{key}" }
    end

    def secret?(key)
      registry_entry(key)[:secret]
    end

    # Typed value for a key: the stored value cast to the registry type, or the
    # registry default when unset. Reads are cheap; callers may cache as needed.
    def get(key)
      key = key.to_s
      record = find_by(key: key)
      raw = record&.value
      return registry_entry(key)[:default] if raw.nil?

      cast(raw, registry_entry(key)[:type])
    end

    # Upserts a value for a known key. `nil`/blank clears it back to the default.
    def set(key, raw)
      key = key.to_s
      registry_entry(key) # validates key is known
      record = find_or_initialize_by(key: key)
      record.value = serialize(raw)
      record.save!
      record
    end

    # The full configuration snapshot: every known key with its effective value,
    # secret flag, whether it has been explicitly configured, and description.
    def snapshot
      stored = where(key: KEYS).index_by(&:key)
      REGISTRY.map do |key, meta|
        record = stored[key]
        configured = record&.value.present?
        {
          key: key,
          type: meta[:type],
          secret: meta[:secret],
          description: meta[:description],
          configured: configured,
          # Secret values are never surfaced; non-secrets return the effective value.
          value: meta[:secret] ? nil : (record ? cast(record.value, meta[:type]) : meta[:default])
        }
      end
    end

    def cast(raw, type)
      return nil if raw.nil?

      case type
      when :boolean then ActiveModel::Type::Boolean.new.cast(raw)
      when :integer then raw.to_s.strip.empty? ? nil : Integer(raw, exception: false)
      else raw.to_s
      end
    end

    def serialize(raw)
      return nil if raw.nil?
      return nil if raw.is_a?(String) && raw.strip.empty?

      raw.to_s
    end
  end
end
