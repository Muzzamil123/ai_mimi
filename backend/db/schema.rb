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

ActiveRecord::Schema[7.1].define(version: 2026_07_17_100001) do
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
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "approval_requests", "characters", on_delete: :cascade
  add_foreign_key "approval_requests", "projects", on_delete: :cascade
  add_foreign_key "approval_requests", "users", on_delete: :cascade
  add_foreign_key "character_images", "characters", on_delete: :cascade
  add_foreign_key "characters", "projects", on_delete: :cascade
  add_foreign_key "project_status_changes", "projects", on_delete: :cascade
  add_foreign_key "project_status_changes", "users", column: "actor_id", on_delete: :nullify
  add_foreign_key "projects", "characters", column: "active_character_id", on_delete: :nullify
  add_foreign_key "projects", "users"
  add_foreign_key "refresh_tokens", "users", on_delete: :cascade
end
