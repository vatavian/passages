# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_09_02_195247) do

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.integer "record_id", null: false
    t.integer "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "passages", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "user_id"
    t.string "uuid", limit: 36
    t.integer "body_id"
    t.string "body_type", limit: 32
    t.index ["user_id"], name: "index_passages_on_user_id"
  end

  create_table "stories", force: :cascade do |t|
    t.integer "start_passage_id"
    t.integer "user_id", null: false
    t.integer "story_format_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "name"
    t.string "ifid"
    t.string "zoom"
    t.text "script"
    t.integer "story_passages_count", default: 0
    t.integer "style_p_id"
    t.index ["start_passage_id"], name: "index_stories_on_start_passage_id"
    t.index ["story_format_id"], name: "index_stories_on_story_format_id"
    t.index ["user_id"], name: "index_stories_on_user_id"
  end

  create_table "story_formats", force: :cascade do |t|
    t.string "name"
    t.string "author"
    t.text "header"
    t.text "footer"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "version"
  end

  create_table "story_passages", force: :cascade do |t|
    t.integer "story_id", null: false
    t.integer "passage_id", null: false
    t.integer "sequence"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "tags"
    t.string "position"
    t.string "size"
    t.index ["passage_id"], name: "index_story_passages_on_passage_id"
    t.index ["story_id"], name: "index_story_passages_on_story_id"
  end

  create_table "text_contents", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "provider"
    t.string "uid"
    t.string "time_zone", limit: 32, default: "UTC"
    t.string "date_format_yesterday", limit: 32, default: "Yesterday %-k:%M"
    t.string "date_format_today", limit: 32, default: "Today %-k:%M"
    t.string "date_format_this_year", limit: 32, default: "%b %-d %-k:%M"
    t.string "date_format_other_year", limit: 32, default: "%Y %b %-d %-k:%M"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "stories", "passages", column: "start_passage_id"
  add_foreign_key "stories", "passages", column: "style_p_id"
  add_foreign_key "stories", "story_formats"
  add_foreign_key "stories", "users"
end
