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

ActiveRecord::Schema[8.0].define(version: 2025_10_12_183131) do
  create_table "artists", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_artists_on_slug", unique: true
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
