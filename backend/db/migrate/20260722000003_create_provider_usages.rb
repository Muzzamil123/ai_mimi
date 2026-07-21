class CreateProviderUsages < ActiveRecord::Migration[7.1]
  def change
    # The authoritative billing ledger: one row per billable provider call
    # (Phase 12: "every billable provider call creates a usage record"). Written
    # idempotently from each provider seam via Usage::Record — the unique
    # (source_type, source_id) pair prevents a job retry from double-counting.
    create_table :provider_usages do |t|
      # Attribution (all nullable — an account/security call may lack a project).
      t.references :user, foreign_key: { on_delete: :nullify }
      t.references :project, foreign_key: { on_delete: :nullify }
      t.references :video, foreign_key: { on_delete: :nullify }

      # The domain record that produced the billable call (Prompt, CharacterImage,
      # VideoGeneration, Video-for-transcription). Polymorphic + not a hard FK so
      # the ledger survives deletion of the source.
      t.string :source_type
      t.bigint :source_id

      t.string :provider, null: false
      t.string :service_type, null: false
      t.string :model
      t.string :provider_request_id

      # Usage units — only the ones relevant to the service are populated.
      t.integer :units
      t.integer :input_tokens
      t.integer :output_tokens
      t.integer :generated_images
      t.decimal :generated_seconds, precision: 12, scale: 3

      t.decimal :estimated_cost, precision: 14, scale: 6, null: false, default: "0"
      t.string :currency, null: false, default: "USD"

      t.jsonb :metadata, null: false, default: {}
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :provider_usages, %i[source_type source_id], unique: true
    add_index :provider_usages, :provider
    add_index :provider_usages, :service_type
    add_index :provider_usages, :occurred_at
    add_index :provider_usages, %i[user_id occurred_at]
    add_index :provider_usages, %i[project_id occurred_at]
  end
end
