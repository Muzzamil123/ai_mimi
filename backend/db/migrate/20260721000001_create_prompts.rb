class CreatePrompts < ActiveRecord::Migration[7.1]
  def change
    create_table :prompts do |t|
      t.references :video, null: false, foreign_key: { on_delete: :cascade }
      t.integer :version, null: false
      t.text :content
      t.text :source_idea
      t.string :provider
      t.string :provider_model
      t.string :provider_request_id
      t.integer :input_tokens
      t.integer :output_tokens
      t.decimal :estimated_cost, precision: 12, scale: 6
      t.integer :status, null: false, default: 0

      # Who created this version — polymorphic so an AI-triggered version records
      # the requesting user and a future automated actor can be attributed too.
      t.string :created_by_type
      t.bigint :created_by_id

      # Idempotency key for the async generation pipeline (rotated per attempt),
      # mirroring Character#generation_id / Video#transcription_id.
      t.string :generation_id

      t.string :failure_reason

      t.timestamps
    end

    # Exactly one row per (video, version); versions increment per video.
    add_index :prompts, [ :video_id, :version ], unique: true
    add_index :prompts, [ :video_id, :status ]
    add_index :prompts, [ :created_by_type, :created_by_id ]

    # Wire the active-prompt pointer staged on videos in Phase 6 (mirrors how
    # projects.active_character_id was wired in Phase 4). Nullify on delete so
    # removing a prompt never cascades into deleting the video. Indexed like
    # projects.active_character_id for the reverse lookup / nullify.
    add_index :videos, :active_prompt_id
    add_foreign_key :videos, :prompts, column: :active_prompt_id, on_delete: :nullify
  end
end
