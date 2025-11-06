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

ActiveRecord::Schema[8.0].define(version: 2025_11_06_033629) do
  create_table "artists", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_artists_on_slug", unique: true
  end

  create_table "grid_exits", force: :cascade do |t|
    t.integer "from_room_id"
    t.integer "to_room_id"
    t.string "direction"
    t.boolean "locked"
    t.integer "requires_item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_room_id"], name: "index_grid_exits_on_from_room_id"
    t.index ["to_room_id"], name: "index_grid_exits_on_to_room_id"
  end

  create_table "grid_factions", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.text "description"
    t.string "color_scheme"
    t.integer "artist_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "grid_hackrs", force: :cascade do |t|
    t.string "hackr_alias"
    t.string "password_digest"
    t.integer "current_room_id"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hackr_alias"], name: "index_grid_hackrs_on_hackr_alias", unique: true
    t.index ["role"], name: "index_grid_hackrs_on_role"
  end

  create_table "grid_items", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "item_type"
    t.integer "room_id"
    t.integer "grid_hackr_id"
    t.json "properties"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "grid_messages", force: :cascade do |t|
    t.integer "grid_hackr_id"
    t.integer "room_id"
    t.string "message_type"
    t.text "content"
    t.integer "target_hackr_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "grid_mobs", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "grid_room_id"
    t.string "mob_type"
    t.json "dialogue_tree"
    t.integer "grid_faction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "grid_rooms", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "grid_zone_id", null: false
    t.string "room_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grid_zone_id"], name: "index_grid_rooms_on_grid_zone_id"
  end

  create_table "grid_zones", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.text "description"
    t.string "zone_type"
    t.string "color_scheme"
    t.integer "grid_faction_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "redirects", force: :cascade do |t|
    t.string "domain"
    t.string "path"
    t.string "destination_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain", "path"], name: "index_redirects_on_domain_and_path", unique: true
  end

  create_table "tracks", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.integer "artist_id", null: false
    t.string "album"
    t.string "album_type"
    t.date "release_date"
    t.string "duration"
    t.string "cover_image"
    t.boolean "featured", default: false
    t.text "streaming_links"
    t.text "videos"
    t.text "lyrics"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["artist_id", "slug"], name: "index_tracks_on_artist_id_and_slug", unique: true
    t.index ["artist_id"], name: "index_tracks_on_artist_id"
    t.index ["featured"], name: "index_tracks_on_featured"
    t.index ["release_date"], name: "index_tracks_on_release_date"
  end

  add_foreign_key "tracks", "artists"
end
