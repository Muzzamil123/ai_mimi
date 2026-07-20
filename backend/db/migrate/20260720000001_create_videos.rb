class CreateVideos < ActiveRecord::Migration[7.1]
  def change
    create_table :videos do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.string :title, null: false
      t.text :idea_text
      t.string :idea_audio_storage_key
      t.text :transcript
      t.string :language, null: false
      t.string :tone
      t.integer :duration_seconds, null: false, default: 15
      t.integer :status, null: false, default: 0

      # Idempotency key for the async transcription pipeline (rotated on each
      # audio upload), mirroring Character#generation_id.
      t.string :transcription_id

      # Transcription provider metadata (populated after a successful transcribe).
      t.string :transcription_provider
      t.string :transcription_provider_model
      t.string :transcription_provider_request_id
      t.decimal :transcription_cost, precision: 12, scale: 6
      t.string :transcription_failure_reason

      # The active prompt is introduced in Phase 7. The column is staged here (a
      # plain nullable reference with no FK/association yet) exactly as
      # projects.active_character_id was staged in Phase 3.
      t.bigint :active_prompt_id

      t.timestamps
    end

    add_index :videos, [ :project_id, :status ]
    add_index :videos, :transcription_id
  end
end
