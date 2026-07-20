class CreateVideoAssets < ActiveRecord::Migration[7.1]
  def change
    create_table :video_assets do |t|
      # One asset per completed generation output.
      t.references :video_generation, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }

      t.string :storage_key
      t.string :filename
      t.string :mime_type
      t.integer :width
      t.integer :height
      t.integer :duration_seconds
      t.bigint :file_size
      t.string :checksum
      t.string :thumbnail_storage_key
      t.integer :validation_status, null: false, default: 0

      # Set once the asset is permanently stored and ready to serve.
      t.datetime :stored_at

      # When identical bytes were already stored for another output of the same
      # video, this points at that original (dedup) instead of storing twice.
      t.references :duplicate_of, foreign_key: { to_table: :video_assets, on_delete: :nullify }

      t.timestamps
    end

    add_index :video_assets, :checksum
  end
end
