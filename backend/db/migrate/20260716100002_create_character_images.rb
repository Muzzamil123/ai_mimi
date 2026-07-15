class CreateCharacterImages < ActiveRecord::Migration[7.1]
  def change
    create_table :character_images do |t|
      t.references :character, null: false, foreign_key: { on_delete: :cascade }

      t.string :storage_key, null: false
      t.string :original_filename
      t.string :mime_type
      t.integer :width
      t.integer :height
      t.bigint :file_size
      t.string :checksum
      t.string :provider_asset_id

      t.timestamps
    end

    add_index :character_images, :storage_key, unique: true
  end
end
