# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_07_22_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "plpgsql"

  create_table "approval_requests", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "character_id", null: false
    t.bigint "user_id", null: false
    t.string "recipient_email", null: false
    t.string "token_digest", null: false
    t.integer "status", default: 0, null: false
    t.text "feedback"
    t.datetime "expires_at", null: false
    t.datetime "responded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_approval_requests_on_character_id"
    t.index ["character_id"], name: "index_approval_requests_on_pending_character", unique: true, where: "(status = 0)"
    t.index ["project_id"], name: "index_approval_requests_on_project_id"
    t.index ["status"], name: "index_approval_requests_on_status"
    t.index ["token_digest"], name: "index_approval_requests_on_token_digest", unique: true
    t.index ["user_id"], name: "index_approval_requests_on_user_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "actor_type"
    t.bigint "actor_id"
    t.string "action", null: false
    t.string "resource_type"
    t.bigint "resource_id"
    t.jsonb "metadata", default: {}, null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["actor_type", "actor_id"], name: "index_audit_logs_on_actor_type_and_actor_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["resource_type", "resource_id"], name: "index_audit_logs_on_resource_type_and_resource_id"
  end

  create_table "character_images", force: :cascade do |t|
    t.bigint "character_id", null: false
    t.string "storage_key", null: false
    t.string "original_filename"
    t.string "mime_type"
    t.integer "width"
    t.integer "height"
    t.bigint "file_size"
    t.string "checksum"
    t.string "provider_asset_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_character_images_on_character_id"
    t.index ["storage_key"], name: "index_character_images_on_storage_key", unique: true
  end

  create_table "characters", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "name", null: false
    t.text "description"
    t.jsonb "character_attributes", default: {}, null: false
    t.jsonb "style_preferences", default: {}, null: false
    t.integer "status", default: 0, null: false
    t.string "provider"
    t.string "provider_model"
    t.string "provider_job_id"
    t.decimal "estimated_cost", precision: 12, scale: 6
    t.text "generation_prompt"
    t.uuid "generation_id"
    t.string "failure_reason"
    t.text "rejection_feedback"
    t.datetime "approved_at"
    t.datetime "rejected_at"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_characters_on_project_id_unique", unique: true
    t.index ["status"], name: "index_characters_on_status"
  end

  create_table "email_deliveries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "project_id"
    t.bigint "video_id"
    t.string "email_type", null: false
    t.string "recipient", null: false
    t.string "subject"
    t.string "provider"
    t.string "provider_message_id"
    t.integer "status", default: 0, null: false
    t.text "error_message"
    t.datetime "sent_at"
    t.datetime "delivered_at"
    t.datetime "read_at"
    t.string "dedupe_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dedupe_key"], name: "index_email_deliveries_on_dedupe_key", unique: true
    t.index ["project_id"], name: "index_email_deliveries_on_project_id"
    t.index ["provider_message_id"], name: "index_email_deliveries_on_provider_message_id"
    t.index ["user_id", "created_at"], name: "index_email_deliveries_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_email_deliveries_on_user_id"
    t.index ["video_id"], name: "index_email_deliveries_on_video_id"
  end

  create_table "platform_settings", force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_platform_settings_on_key", unique: true
  end

  create_table "project_status_changes", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.bigint "actor_id"
    t.string "from_status"
    t.string "to_status", null: false
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_project_status_changes_on_actor_id"
    t.index ["project_id"], name: "index_project_status_changes_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.string "default_language", default: "english", null: false
    t.string "default_tone", default: "neutral", null: false
    t.string "target_platforms", default: [], null: false, array: true
    t.integer "status", default: 0, null: false
    t.bigint "active_character_id"
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_character_id"], name: "index_projects_on_active_character_id"
    t.index ["status"], name: "index_projects_on_status"
    t.index ["user_id", "slug"], name: "index_projects_on_user_id_and_slug", unique: true
    t.index ["user_id"], name: "index_projects_on_user_id"
  end

  create_table "prompts", force: :cascade do |t|
    t.bigint "video_id", null: false
    t.integer "version", null: false
    t.text "content"
    t.text "source_idea"
    t.string "provider"
    t.string "provider_model"
    t.string "provider_request_id"
    t.integer "input_tokens"
    t.integer "output_tokens"
    t.decimal "estimated_cost", precision: 12, scale: 6
    t.integer "status", default: 0, null: false
    t.string "created_by_type"
    t.bigint "created_by_id"
    t.string "generation_id"
    t.string "failure_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by_type", "created_by_id"], name: "index_prompts_on_created_by_type_and_created_by_id"
    t.index ["video_id", "status"], name: "index_prompts_on_video_id_and_status"
    t.index ["video_id", "version"], name: "index_prompts_on_video_id_and_version", unique: true
    t.index ["video_id"], name: "index_prompts_on_video_id"
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token_digest", null: false
    t.datetime "expires_at", null: false
    t.datetime "revoked_at"
    t.string "user_agent"
    t.string "ip_address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token_digest"], name: "index_refresh_tokens_on_token_digest", unique: true
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.citext "email", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "email_verified_at"
    t.datetime "last_login_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "notification_preferences", default: {}, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "video_assets", force: :cascade do |t|
    t.bigint "video_generation_id", null: false
    t.string "storage_key"
    t.string "filename"
    t.string "mime_type"
    t.integer "width"
    t.integer "height"
    t.integer "duration_seconds"
    t.bigint "file_size"
    t.string "checksum"
    t.string "thumbnail_storage_key"
    t.integer "validation_status", default: 0, null: false
    t.datetime "stored_at"
    t.bigint "duplicate_of_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["checksum"], name: "index_video_assets_on_checksum"
    t.index ["duplicate_of_id"], name: "index_video_assets_on_duplicate_of_id"
    t.index ["video_generation_id"], name: "index_video_assets_on_video_generation_id", unique: true
  end

  create_table "video_generations", force: :cascade do |t|
    t.bigint "video_id", null: false
    t.bigint "project_id", null: false
    t.bigint "character_id", null: false
    t.bigint "prompt_id", null: false
    t.string "aspect_ratio", null: false
    t.integer "variation_number", null: false
    t.integer "duration_seconds", default: 15, null: false
    t.string "provider"
    t.string "provider_model"
    t.string "provider_job_id"
    t.string "provider_request_id"
    t.integer "status", default: 0, null: false
    t.integer "attempt_count", default: 0, null: false
    t.integer "progress", default: 0, null: false
    t.decimal "estimated_cost", precision: 12, scale: 6
    t.string "error_code"
    t.string "error_message"
    t.string "idempotency_key", null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_video_generations_on_character_id"
    t.index ["idempotency_key"], name: "index_video_generations_on_idempotency_key", unique: true
    t.index ["project_id"], name: "index_video_generations_on_project_id"
    t.index ["prompt_id"], name: "index_video_generations_on_prompt_id"
    t.index ["provider_job_id"], name: "index_video_generations_on_provider_job_id"
    t.index ["video_id", "status"], name: "index_video_generations_on_video_id_and_status"
    t.index ["video_id"], name: "index_video_generations_on_video_id"
  end

  create_table "video_status_changes", force: :cascade do |t|
    t.bigint "video_id", null: false
    t.bigint "actor_id"
    t.string "from_status"
    t.string "to_status", null: false
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_video_status_changes_on_actor_id"
    t.index ["video_id", "created_at"], name: "index_video_status_changes_on_video_id_and_created_at"
    t.index ["video_id"], name: "index_video_status_changes_on_video_id"
  end

  create_table "videos", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.string "title", null: false
    t.text "idea_text"
    t.string "idea_audio_storage_key"
    t.text "transcript"
    t.string "language", null: false
    t.string "tone"
    t.integer "duration_seconds", default: 15, null: false
    t.integer "status", default: 0, null: false
    t.string "transcription_id"
    t.string "transcription_provider"
    t.string "transcription_provider_model"
    t.string "transcription_provider_request_id"
    t.decimal "transcription_cost", precision: 12, scale: 6
    t.string "transcription_failure_reason"
    t.bigint "active_prompt_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_prompt_id"], name: "index_videos_on_active_prompt_id"
    t.index ["project_id", "status"], name: "index_videos_on_project_id_and_status"
    t.index ["project_id"], name: "index_videos_on_project_id"
    t.index ["transcription_id"], name: "index_videos_on_transcription_id"
  end

  add_foreign_key "approval_requests", "characters", on_delete: :cascade
  add_foreign_key "approval_requests", "projects", on_delete: :cascade
  add_foreign_key "approval_requests", "users", on_delete: :cascade
  add_foreign_key "character_images", "characters", on_delete: :cascade
  add_foreign_key "characters", "projects", on_delete: :cascade
  add_foreign_key "email_deliveries", "projects", on_delete: :nullify
  add_foreign_key "email_deliveries", "users", on_delete: :cascade
  add_foreign_key "email_deliveries", "videos", on_delete: :nullify
  add_foreign_key "project_status_changes", "projects", on_delete: :cascade
  add_foreign_key "project_status_changes", "users", column: "actor_id", on_delete: :nullify
  add_foreign_key "projects", "characters", column: "active_character_id", on_delete: :nullify
  add_foreign_key "projects", "users"
  add_foreign_key "prompts", "videos", on_delete: :cascade
  add_foreign_key "refresh_tokens", "users", on_delete: :cascade
  add_foreign_key "video_assets", "video_assets", column: "duplicate_of_id", on_delete: :nullify
  add_foreign_key "video_assets", "video_generations", on_delete: :cascade
  add_foreign_key "video_generations", "characters", on_delete: :cascade
  add_foreign_key "video_generations", "projects", on_delete: :cascade
  add_foreign_key "video_generations", "prompts", on_delete: :cascade
  add_foreign_key "video_generations", "videos", on_delete: :cascade
  add_foreign_key "video_status_changes", "users", column: "actor_id", on_delete: :nullify
  add_foreign_key "video_status_changes", "videos", on_delete: :cascade
  add_foreign_key "videos", "projects", on_delete: :cascade
  add_foreign_key "videos", "prompts", column: "active_prompt_id", on_delete: :nullify
end
