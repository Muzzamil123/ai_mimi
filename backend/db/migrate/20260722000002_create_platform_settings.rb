class CreatePlatformSettings < ActiveRecord::Migration[7.1]
  def change
    # Admin-managed platform configuration (Phase 11: "platform settings" /
    # "update platform configuration"). One row per known setting key (see
    # PlatformSetting::REGISTRY). `value` is stored encrypted at rest (Active
    # Record encryption) because some settings are provider secrets; the API
    # never echoes a secret value back (masked in the blueprint).
    create_table :platform_settings do |t|
      t.string :key, null: false
      # Encrypted ciphertext is longer than the plaintext, so use text.
      t.text :value
      t.timestamps
    end

    add_index :platform_settings, :key, unique: true
  end
end
