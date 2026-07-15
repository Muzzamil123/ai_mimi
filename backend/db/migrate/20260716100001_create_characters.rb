class CreateCharacters < ActiveRecord::Migration[7.1]
  def change
    create_table :characters do |t|
      t.references :project, null: false, index: false,
                   foreign_key: { on_delete: :cascade }

      t.string :name, null: false
      t.text :description
      # `attributes` is reserved by ActiveRecord, so the column is namespaced and
      # exposed as `attributes` at the serialization layer.
      t.jsonb :character_attributes, null: false, default: {}
      t.jsonb :style_preferences, null: false, default: {}

      t.integer :status, null: false, default: 0

      # Provider abstraction bookkeeping (populated by CharacterImageProviders::*).
      t.string :provider
      t.string :provider_model
      t.string :provider_job_id
      t.decimal :estimated_cost, precision: 12, scale: 6

      t.text :generation_prompt
      # Rotates on every (re)generation so stale/duplicate background jobs no-op.
      t.uuid :generation_id
      t.string :failure_reason
      t.text :rejection_feedback

      t.datetime :approved_at
      t.datetime :rejected_at
      t.datetime :locked_at

      t.timestamps
    end

    # One project owns exactly one character (mandatory business rule).
    add_index :characters, :project_id, unique: true, name: "index_characters_on_project_id_unique"
    add_index :characters, :status
  end
end
