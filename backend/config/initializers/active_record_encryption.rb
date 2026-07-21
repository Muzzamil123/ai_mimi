# Keys for Active Record encryption, used to encrypt sensitive PlatformSetting
# values (provider API keys) at rest. Production MUST supply real, rotated keys
# via ENV. Off-production we derive deterministic keys from secret_key_base so
# the app boots with no extra setup (dev/test/CI) — these derived keys are not a
# secret and must never be relied on in production.
Rails.application.configure do
  derive = lambda do |label|
    ActiveSupport::KeyGenerator
      .new(Rails.application.secret_key_base.to_s)
      .generate_key(label, 32)
      .unpack1("H*")
  end

  config.active_record.encryption.primary_key =
    ENV.fetch("AR_ENCRYPTION_PRIMARY_KEY") { derive.call("ar-encryption-primary-v1") }
  config.active_record.encryption.deterministic_key =
    ENV.fetch("AR_ENCRYPTION_DETERMINISTIC_KEY") { derive.call("ar-encryption-deterministic-v1") }
  config.active_record.encryption.key_derivation_salt =
    ENV.fetch("AR_ENCRYPTION_KEY_DERIVATION_SALT") { derive.call("ar-encryption-salt-v1") }
end
