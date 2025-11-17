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

ActiveRecord::Schema[8.1].define(version: 2025_11_17_175844) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "albums", force: :cascade do |t|
    t.string "album_type"
    t.integer "artist_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.date "release_date"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["artist_id", "slug"], name: "index_albums_on_artist_id_and_slug", unique: true
    t.index ["artist_id"], name: "index_albums_on_artist_id"
  end

  create_table "artists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "genre"
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_artists_on_slug", unique: true
  end

  create_table "grid_exits", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "direction"
    t.integer "from_room_id"
    t.boolean "locked"
    t.integer "requires_item_id"
    t.integer "to_room_id"
    t.datetime "updated_at", null: false
    t.index ["from_room_id"], name: "index_grid_exits_on_from_room_id"
    t.index ["to_room_id"], name: "index_grid_exits_on_to_room_id"
  end

  create_table "grid_factions", force: :cascade do |t|
    t.integer "artist_id"
    t.string "color_scheme"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", null: false
  end

  create_table "grid_hackrs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "current_room_id"
    t.string "hackr_alias"
    t.string "password_digest"
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["hackr_alias"], name: "index_grid_hackrs_on_hackr_alias", unique: true
    t.index ["role"], name: "index_grid_hackrs_on_role"
  end

  create_table "grid_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "grid_hackr_id"
    t.string "item_type"
    t.string "name"
    t.json "properties"
    t.integer "room_id"
    t.datetime "updated_at", null: false
  end

  create_table "grid_messages", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "grid_hackr_id"
    t.string "message_type"
    t.integer "room_id"
    t.integer "target_hackr_id"
    t.datetime "updated_at", null: false
  end

  create_table "grid_mobs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.json "dialogue_tree"
    t.integer "grid_faction_id"
    t.integer "grid_room_id"
    t.string "mob_type"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "grid_rooms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "grid_zone_id", null: false
    t.string "name"
    t.string "room_type"
    t.datetime "updated_at", null: false
    t.index ["grid_zone_id"], name: "index_grid_rooms_on_grid_zone_id"
  end

  create_table "grid_zones", force: :cascade do |t|
    t.string "color_scheme"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "grid_faction_id"
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.string "zone_type"
  end

  create_table "hackr_logs", force: :cascade do |t|
    t.integer "author_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_hackr_logs_on_author_id"
    t.index ["slug"], name: "index_hackr_logs_on_slug", unique: true
  end

  create_table "playlist_tracks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "playlist_id", null: false
    t.integer "position", null: false
    t.integer "track_id", null: false
    t.datetime "updated_at", null: false
    t.index ["playlist_id", "position"], name: "index_playlist_tracks_on_playlist_id_and_position"
    t.index ["playlist_id", "track_id"], name: "index_playlist_tracks_on_playlist_id_and_track_id", unique: true
    t.index ["playlist_id"], name: "index_playlist_tracks_on_playlist_id"
    t.index ["track_id"], name: "index_playlist_tracks_on_track_id"
  end

  create_table "playlists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "grid_hackr_id", null: false
    t.boolean "is_public", default: false, null: false
    t.string "name", null: false
    t.string "share_token", null: false
    t.datetime "updated_at", null: false
    t.index ["grid_hackr_id"], name: "index_playlists_on_grid_hackr_id"
    t.index ["share_token"], name: "index_playlists_on_share_token", unique: true
  end

  create_table "radio_station_playlists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "playlist_id", null: false
    t.integer "position", default: 0, null: false
    t.integer "radio_station_id", null: false
    t.datetime "updated_at", null: false
    t.index ["playlist_id"], name: "index_radio_station_playlists_on_playlist_id"
    t.index ["radio_station_id", "playlist_id"], name: "index_radio_station_playlists_unique", unique: true
    t.index ["radio_station_id", "position"], name: "index_radio_station_playlists_position"
    t.index ["radio_station_id"], name: "index_radio_station_playlists_on_radio_station_id"
  end

  create_table "radio_stations", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "genre"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.string "stream_url"
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_radio_stations_on_position"
    t.index ["slug"], name: "index_radio_stations_on_slug", unique: true
  end

  create_table "redirects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "destination_url"
    t.string "domain"
    t.string "path"
    t.datetime "updated_at", null: false
    t.index ["domain", "path"], name: "index_redirects_on_domain_and_path", unique: true
  end

  create_table "tracks", force: :cascade do |t|
    t.integer "album_id", null: false
    t.integer "artist_id", null: false
    t.string "cover_image"
    t.datetime "created_at", null: false
    t.string "duration"
    t.boolean "featured", default: false
    t.text "lyrics"
    t.date "release_date"
    t.string "slug"
    t.text "streaming_links"
    t.string "title"
    t.integer "track_number"
    t.datetime "updated_at", null: false
    t.text "videos"
    t.index ["album_id"], name: "index_tracks_on_album_id"
    t.index ["artist_id", "slug"], name: "index_tracks_on_artist_id_and_slug", unique: true
    t.index ["artist_id"], name: "index_tracks_on_artist_id"
    t.index ["featured"], name: "index_tracks_on_featured"
    t.index ["release_date"], name: "index_tracks_on_release_date"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "albums", "artists"
  add_foreign_key "hackr_logs", "grid_hackrs", column: "author_id"
  add_foreign_key "playlist_tracks", "playlists"
  add_foreign_key "playlist_tracks", "tracks"
  add_foreign_key "playlists", "grid_hackrs"
  add_foreign_key "radio_station_playlists", "playlists"
  add_foreign_key "radio_station_playlists", "radio_stations"
  add_foreign_key "tracks", "albums"
  add_foreign_key "tracks", "artists"
end
