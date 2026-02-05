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

ActiveRecord::Schema[8.1].define(version: 2026_02_05_000002) do
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
    t.string "artist_type", default: "band", null: false
    t.datetime "created_at", null: false
    t.string "genre"
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_artists_on_slug", unique: true
  end

  create_table "chat_channels", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_active", default: true, null: false
    t.string "minimum_role", default: "operative", null: false
    t.string "name", null: false
    t.boolean "requires_livestream", default: false, null: false
    t.integer "slow_mode_seconds", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["is_active"], name: "index_chat_channels_on_is_active"
    t.index ["slug"], name: "index_chat_channels_on_slug", unique: true
  end

  create_table "chat_messages", force: :cascade do |t|
    t.integer "chat_channel_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.boolean "dropped", default: false, null: false
    t.datetime "dropped_at"
    t.integer "grid_hackr_id", null: false
    t.integer "hackr_stream_id"
    t.datetime "updated_at", null: false
    t.index ["chat_channel_id", "created_at"], name: "index_chat_messages_on_chat_channel_id_and_created_at"
    t.index ["chat_channel_id"], name: "index_chat_messages_on_chat_channel_id"
    t.index ["dropped"], name: "index_chat_messages_on_dropped"
    t.index ["grid_hackr_id"], name: "index_chat_messages_on_grid_hackr_id"
    t.index ["hackr_stream_id"], name: "index_chat_messages_on_hackr_stream_id"
  end

  create_table "codex_entries", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.string "entry_type", null: false
    t.json "metadata", default: {}
    t.string "name", null: false
    t.integer "position"
    t.boolean "published", default: false, null: false
    t.string "slug", null: false
    t.text "summary"
    t.datetime "updated_at", null: false
    t.index ["entry_type"], name: "index_codex_entries_on_entry_type"
    t.index ["published"], name: "index_codex_entries_on_published"
    t.index ["slug"], name: "index_codex_entries_on_slug", unique: true
  end

  create_table "echoes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "echoed_at", null: false
    t.integer "grid_hackr_id", null: false
    t.boolean "is_seed", default: false, null: false
    t.integer "pulse_id", null: false
    t.datetime "updated_at", null: false
    t.index ["echoed_at"], name: "index_echoes_on_echoed_at"
    t.index ["grid_hackr_id"], name: "index_echoes_on_grid_hackr_id"
    t.index ["is_seed"], name: "index_echoes_on_is_seed"
    t.index ["pulse_id", "grid_hackr_id"], name: "index_echoes_on_pulse_id_and_grid_hackr_id", unique: true
    t.index ["pulse_id"], name: "index_echoes_on_pulse_id"
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
    t.string "api_token"
    t.datetime "created_at", null: false
    t.integer "current_room_id"
    t.string "email"
    t.string "hackr_alias"
    t.datetime "last_activity_at"
    t.string "password_digest"
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["api_token"], name: "index_grid_hackrs_on_api_token", unique: true
    t.index ["email"], name: "index_grid_hackrs_on_email", unique: true
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

  create_table "grid_registration_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.string "ip_address"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.index ["email"], name: "index_grid_registration_tokens_on_email"
    t.index ["token"], name: "index_grid_registration_tokens_on_token", unique: true
  end

  create_table "grid_rooms", force: :cascade do |t|
    t.integer "ambient_playlist_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "grid_zone_id", null: false
    t.string "name"
    t.string "room_type"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["ambient_playlist_id"], name: "index_grid_rooms_on_ambient_playlist_id"
    t.index ["grid_zone_id"], name: "index_grid_rooms_on_grid_zone_id"
    t.index ["slug"], name: "index_grid_rooms_on_slug", unique: true
  end

  create_table "grid_zones", force: :cascade do |t|
    t.integer "ambient_playlist_id"
    t.string "color_scheme"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "grid_faction_id"
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.string "zone_type"
    t.index ["ambient_playlist_id"], name: "index_grid_zones_on_ambient_playlist_id"
  end

  create_table "hackr_logs", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "grid_hackr_id", null: false
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["grid_hackr_id"], name: "index_hackr_logs_on_grid_hackr_id"
    t.index ["slug"], name: "index_hackr_logs_on_slug", unique: true
  end

  create_table "hackr_streams", force: :cascade do |t|
    t.integer "artist_id", null: false
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.boolean "is_live", default: false, null: false
    t.string "live_url"
    t.datetime "started_at"
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "vod_url"
    t.index ["artist_id"], name: "index_hackr_streams_on_artist_id"
  end

  create_table "moderation_logs", force: :cascade do |t|
    t.string "action", null: false
    t.integer "actor_id", null: false
    t.integer "chat_message_id"
    t.datetime "created_at", null: false
    t.integer "duration_minutes"
    t.text "reason"
    t.integer "target_id"
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_moderation_logs_on_action"
    t.index ["actor_id"], name: "index_moderation_logs_on_actor_id"
    t.index ["chat_message_id"], name: "index_moderation_logs_on_chat_message_id"
    t.index ["created_at"], name: "index_moderation_logs_on_created_at"
    t.index ["target_id"], name: "index_moderation_logs_on_target_id"
  end

  create_table "overlay_alerts", force: :cascade do |t|
    t.string "alert_type", null: false
    t.datetime "created_at", null: false
    t.json "data", default: {}
    t.boolean "displayed", default: false
    t.datetime "displayed_at"
    t.datetime "expires_at"
    t.text "message"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["alert_type"], name: "index_overlay_alerts_on_alert_type"
    t.index ["displayed"], name: "index_overlay_alerts_on_displayed"
    t.index ["expires_at"], name: "index_overlay_alerts_on_expires_at"
  end

  create_table "overlay_elements", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.string "element_type", null: false
    t.string "name", null: false
    t.json "settings", default: {}
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_overlay_elements_on_active"
    t.index ["element_type"], name: "index_overlay_elements_on_element_type"
    t.index ["slug"], name: "index_overlay_elements_on_slug", unique: true
  end

  create_table "overlay_lower_thirds", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.string "logo_url"
    t.string "name", null: false
    t.string "primary_text", null: false
    t.string "secondary_text"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_overlay_lower_thirds_on_active"
    t.index ["slug"], name: "index_overlay_lower_thirds_on_slug", unique: true
  end

  create_table "overlay_now_playing", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "custom_artist"
    t.string "custom_title"
    t.boolean "is_live", default: false
    t.boolean "paused", default: false, null: false
    t.datetime "started_at"
    t.integer "track_id"
    t.datetime "updated_at", null: false
    t.index ["track_id"], name: "index_overlay_now_playing_on_track_id"
  end

  create_table "overlay_scene_elements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "height"
    t.integer "overlay_element_id", null: false
    t.integer "overlay_scene_id", null: false
    t.json "overrides", default: {}
    t.datetime "updated_at", null: false
    t.integer "width"
    t.integer "x", default: 0
    t.integer "y", default: 0
    t.integer "z_index", default: 0
    t.index ["overlay_element_id"], name: "index_overlay_scene_elements_on_overlay_element_id"
    t.index ["overlay_scene_id", "overlay_element_id"], name: "idx_scene_elements_composite"
    t.index ["overlay_scene_id"], name: "index_overlay_scene_elements_on_overlay_scene_id"
    t.index ["z_index"], name: "index_overlay_scene_elements_on_z_index"
  end

  create_table "overlay_scene_group_scenes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "overlay_scene_group_id", null: false
    t.integer "overlay_scene_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["overlay_scene_group_id", "overlay_scene_id"], name: "index_scene_group_scenes_unique", unique: true
    t.index ["overlay_scene_group_id", "position"], name: "index_scene_group_scenes_position"
    t.index ["overlay_scene_group_id"], name: "index_overlay_scene_group_scenes_on_overlay_scene_group_id"
    t.index ["overlay_scene_id"], name: "index_overlay_scene_group_scenes_on_overlay_scene_id"
  end

  create_table "overlay_scene_groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_overlay_scene_groups_on_slug", unique: true
  end

  create_table "overlay_scenes", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.integer "height", default: 1080
    t.string "name", null: false
    t.integer "position", default: 0
    t.string "scene_type", default: "composition", null: false
    t.json "settings", default: {}
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.integer "width", default: 1920
    t.index ["active"], name: "index_overlay_scenes_on_active"
    t.index ["scene_type"], name: "index_overlay_scenes_on_scene_type"
    t.index ["slug"], name: "index_overlay_scenes_on_slug", unique: true
  end

  create_table "overlay_tickers", force: :cascade do |t|
    t.boolean "active", default: true
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.string "direction", default: "left"
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "speed", default: 50
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_overlay_tickers_on_active"
    t.index ["slug"], name: "index_overlay_tickers_on_slug", unique: true
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

  create_table "pulses", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.integer "echo_count", default: 0, null: false
    t.integer "grid_hackr_id", null: false
    t.boolean "is_seed", default: false, null: false
    t.integer "parent_pulse_id"
    t.datetime "pulsed_at", null: false
    t.boolean "signal_dropped", default: false, null: false
    t.datetime "signal_dropped_at"
    t.integer "splice_count", default: 0, null: false
    t.integer "thread_root_id"
    t.datetime "updated_at", null: false
    t.index ["grid_hackr_id"], name: "index_pulses_on_grid_hackr_id"
    t.index ["is_seed"], name: "index_pulses_on_is_seed"
    t.index ["parent_pulse_id"], name: "index_pulses_on_parent_pulse_id"
    t.index ["pulsed_at"], name: "index_pulses_on_pulsed_at"
    t.index ["signal_dropped"], name: "index_pulses_on_signal_dropped"
    t.index ["thread_root_id"], name: "index_pulses_on_thread_root_id"
  end

  create_table "radio_station_playlists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "playlist_id", null: false
    t.integer "position", null: false
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
    t.boolean "show_in_pulse_vault", default: true, null: false
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

  create_table "user_punishments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.integer "grid_hackr_id", null: false
    t.integer "issued_by_id", null: false
    t.string "punishment_type", null: false
    t.text "reason"
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_user_punishments_on_expires_at"
    t.index ["grid_hackr_id", "punishment_type"], name: "index_user_punishments_on_grid_hackr_id_and_punishment_type"
    t.index ["grid_hackr_id"], name: "index_user_punishments_on_grid_hackr_id"
    t.index ["issued_by_id"], name: "index_user_punishments_on_issued_by_id"
  end

  create_table "zone_playlist_tracks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", null: false
    t.integer "track_id", null: false
    t.datetime "updated_at", null: false
    t.integer "zone_playlist_id", null: false
    t.index ["track_id"], name: "index_zone_playlist_tracks_on_track_id"
    t.index ["zone_playlist_id", "track_id"], name: "index_zone_playlist_tracks_on_playlist_and_track", unique: true
    t.index ["zone_playlist_id"], name: "index_zone_playlist_tracks_on_zone_playlist_id"
  end

  create_table "zone_playlists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "crossfade_duration_ms", default: 5000, null: false
    t.decimal "default_volume", precision: 3, scale: 2, default: "0.35", null: false
    t.text "description"
    t.string "name", null: false
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_zone_playlists_on_slug", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "albums", "artists"
  add_foreign_key "chat_messages", "chat_channels"
  add_foreign_key "chat_messages", "grid_hackrs"
  add_foreign_key "chat_messages", "hackr_streams"
  add_foreign_key "echoes", "grid_hackrs"
  add_foreign_key "echoes", "pulses"
  add_foreign_key "grid_rooms", "zone_playlists", column: "ambient_playlist_id"
  add_foreign_key "grid_zones", "zone_playlists", column: "ambient_playlist_id"
  add_foreign_key "hackr_logs", "grid_hackrs"
  add_foreign_key "hackr_streams", "artists"
  add_foreign_key "moderation_logs", "chat_messages"
  add_foreign_key "moderation_logs", "grid_hackrs", column: "actor_id"
  add_foreign_key "moderation_logs", "grid_hackrs", column: "target_id"
  add_foreign_key "overlay_now_playing", "tracks"
  add_foreign_key "overlay_scene_elements", "overlay_elements"
  add_foreign_key "overlay_scene_elements", "overlay_scenes"
  add_foreign_key "overlay_scene_group_scenes", "overlay_scene_groups"
  add_foreign_key "overlay_scene_group_scenes", "overlay_scenes"
  add_foreign_key "playlist_tracks", "playlists"
  add_foreign_key "playlist_tracks", "tracks"
  add_foreign_key "playlists", "grid_hackrs"
  add_foreign_key "pulses", "grid_hackrs"
  add_foreign_key "pulses", "pulses", column: "parent_pulse_id"
  add_foreign_key "pulses", "pulses", column: "thread_root_id"
  add_foreign_key "radio_station_playlists", "playlists"
  add_foreign_key "radio_station_playlists", "radio_stations"
  add_foreign_key "tracks", "albums"
  add_foreign_key "tracks", "artists"
  add_foreign_key "user_punishments", "grid_hackrs"
  add_foreign_key "user_punishments", "grid_hackrs", column: "issued_by_id"
  add_foreign_key "zone_playlist_tracks", "tracks"
  add_foreign_key "zone_playlist_tracks", "zone_playlists"
end
