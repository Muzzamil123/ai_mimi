class CreateProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :projects do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :default_language, null: false, default: "english"
      t.string :default_tone, null: false, default: "neutral"
      t.string :target_platforms, array: true, null: false, default: []
      t.integer :status, null: false, default: 0
      # FK to characters is added in Phase 4 when the characters table exists.
      t.bigint :active_character_id
      t.datetime :archived_at

      t.timestamps
    end

    add_index :projects, %i[user_id slug], unique: true
    add_index :projects, :status
    add_index :projects, :active_character_id
  end
end
