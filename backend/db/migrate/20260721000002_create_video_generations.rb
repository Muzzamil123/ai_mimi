class CreateVideoGenerations < ActiveRecord::Migration[7.1]
  def change
    create_table :video_generations do |t|
      t.references :video, null: false, foreign_key: { on_delete: :cascade }
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      # The approved character/prompt this output was generated from (its
      # provenance). Prompts are superseded, not destroyed, and an approved
      # character is only removed by an admin reset, so cascade is safe: if the
      # source record is ever deleted, its generations go with it.
      t.references :character, null: false, foreign_key: { on_delete: :cascade }
      t.references :prompt, null: false, foreign_key: { on_delete: :cascade }

      t.string :aspect_ratio, null: false
      t.integer :variation_number, null: false
      t.integer :duration_seconds, null: false, default: 15

      t.string :provider
      t.string :provider_model
      t.string :provider_job_id
      t.string :provider_request_id

      t.integer :status, null: false, default: 0
      t.integer :attempt_count, null: false, default: 0
      t.integer :progress, null: false, default: 0
      t.decimal :estimated_cost, precision: 12, scale: 6

      t.string :error_code
      t.string :error_message

      # Deterministic key over (video, prompt, character, aspect, variation) so a
      # repeated generation request never creates a duplicate active job for the
      # same output (idempotency requirement).
      t.string :idempotency_key, null: false

      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :video_generations, :idempotency_key, unique: true
    add_index :video_generations, :provider_job_id
    add_index :video_generations, [ :video_id, :status ]
  end
end
