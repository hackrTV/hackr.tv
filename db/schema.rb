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

ActiveRecord::Schema[8.1].define(version: 2026_04_28_200000) do
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
    t.string "source"
    t.datetime "updated_at", null: false
    t.index ["chat_channel_id", "created_at"], name: "index_chat_messages_on_chat_channel_id_and_created_at"
    t.index ["chat_channel_id"], name: "index_chat_messages_on_chat_channel_id"
    t.index ["dropped"], name: "index_chat_messages_on_dropped"
    t.index ["grid_hackr_id"], name: "index_chat_messages_on_grid_hackr_id"
    t.index ["hackr_stream_id"], name: "index_chat_messages_on_hackr_stream_id"
  end

  create_table "code_repositories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "default_branch"
    t.text "description"
    t.string "full_name", null: false
    t.integer "github_id", null: false
    t.datetime "github_pushed_at"
    t.string "homepage"
    t.string "language"
    t.datetime "last_synced_at"
    t.string "name", null: false
    t.integer "size_kb", default: 0
    t.string "slug", null: false
    t.integer "stargazers_count", default: 0
    t.text "sync_error"
    t.string "sync_status"
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true, null: false
    t.index ["github_id"], name: "index_code_repositories_on_github_id", unique: true
    t.index ["slug"], name: "index_code_repositories_on_slug", unique: true
    t.index ["visible"], name: "index_code_repositories_on_visible"
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

  create_table "codex_entry_reads", force: :cascade do |t|
    t.integer "codex_entry_id", null: false
    t.datetime "created_at", null: false
    t.integer "grid_hackr_id", null: false
    t.datetime "read_at", null: false
    t.datetime "updated_at", null: false
    t.index ["codex_entry_id"], name: "index_codex_entry_reads_on_codex_entry_id"
    t.index ["grid_hackr_id", "codex_entry_id"], name: "index_codex_entry_reads_unique", unique: true
    t.index ["grid_hackr_id"], name: "index_codex_entry_reads_on_grid_hackr_id"
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

  create_table "feature_grants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "feature", null: false
    t.integer "grid_hackr_id", null: false
    t.datetime "updated_at", null: false
    t.index ["feature"], name: "index_feature_grants_on_feature"
    t.index ["grid_hackr_id", "feature"], name: "index_feature_grants_on_grid_hackr_id_and_feature", unique: true
    t.index ["grid_hackr_id"], name: "index_feature_grants_on_grid_hackr_id"
  end

  create_table "grid_achievements", force: :cascade do |t|
    t.string "badge_icon"
    t.string "category", default: "grid", null: false
    t.datetime "created_at", null: false
    t.integer "cred_reward", default: 0, null: false
    t.text "description"
    t.boolean "hidden", default: false, null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.json "trigger_data", default: {}
    t.string "trigger_type", null: false
    t.datetime "updated_at", null: false
    t.integer "xp_reward", default: 0, null: false
    t.index ["category"], name: "index_grid_achievements_on_category"
    t.index ["slug"], name: "index_grid_achievements_on_slug", unique: true
    t.index ["trigger_type"], name: "index_grid_achievements_on_trigger_type"
  end

  create_table "grid_breach_encounters", force: :cascade do |t|
    t.datetime "cooldown_until"
    t.datetime "created_at", null: false
    t.integer "grid_breach_template_id", null: false
    t.integer "grid_room_id", null: false
    t.integer "instance_seed"
    t.string "state", default: "available", null: false
    t.datetime "updated_at", null: false
    t.index ["grid_breach_template_id"], name: "index_grid_breach_encounters_on_grid_breach_template_id"
    t.index ["grid_room_id", "grid_breach_template_id"], name: "index_breach_encounters_on_room_and_template"
    t.index ["grid_room_id"], name: "index_grid_breach_encounters_on_grid_room_id"
    t.index ["state"], name: "index_grid_breach_encounters_on_state"
  end

  create_table "grid_breach_protocols", force: :cascade do |t|
    t.integer "charge_rounds", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "grid_hackr_breach_id", null: false
    t.integer "health", null: false
    t.integer "max_health", null: false
    t.json "meta", default: {}, null: false
    t.integer "position", null: false
    t.string "protocol_type", null: false
    t.boolean "rerouted", default: false, null: false
    t.integer "rounds_charging", default: 0, null: false
    t.string "state", default: "idle", null: false
    t.datetime "updated_at", null: false
    t.string "weakness"
    t.index ["grid_hackr_breach_id", "position"], name: "index_breach_protocols_on_breach_and_position", unique: true
    t.index ["grid_hackr_breach_id"], name: "index_grid_breach_protocols_on_grid_hackr_breach_id"
  end

  create_table "grid_breach_templates", force: :cascade do |t|
    t.integer "base_detection_rate", default: 5, null: false
    t.integer "cooldown_max", default: 600, null: false
    t.integer "cooldown_min", default: 300, null: false
    t.datetime "created_at", null: false
    t.integer "cred_reward", default: 0, null: false
    t.integer "danger_level_min", default: 0, null: false
    t.text "description"
    t.integer "min_clearance", default: 0, null: false
    t.string "name", null: false
    t.boolean "no_clearance_bypass", default: false, null: false
    t.integer "pnr_threshold", default: 75, null: false
    t.integer "position", default: 0, null: false
    t.json "protocol_composition", default: {}, null: false
    t.boolean "published", default: false, null: false
    t.json "puzzle_gates", default: [], null: false
    t.string "requires_item_slug"
    t.string "requires_mission_slug"
    t.json "reward_table", default: {}, null: false
    t.string "slug", null: false
    t.string "tier", default: "standard", null: false
    t.datetime "updated_at", null: false
    t.integer "xp_reward", default: 0, null: false
    t.json "zone_slugs", default: [], null: false
    t.index ["published"], name: "index_grid_breach_templates_on_published"
    t.index ["slug"], name: "index_grid_breach_templates_on_slug", unique: true
    t.index ["tier"], name: "index_grid_breach_templates_on_tier"
  end

  create_table "grid_caches", force: :cascade do |t|
    t.string "address", null: false
    t.datetime "archived_at"
    t.datetime "created_at", null: false
    t.integer "grid_hackr_id"
    t.boolean "is_default", default: false, null: false
    t.string "nickname"
    t.string "status", default: "active", null: false
    t.string "system_type"
    t.datetime "updated_at", null: false
    t.index ["address"], name: "index_grid_caches_on_address", unique: true
    t.index ["grid_hackr_id", "nickname"], name: "index_grid_caches_on_hackr_nickname", unique: true, where: "nickname IS NOT NULL"
    t.index ["grid_hackr_id"], name: "index_grid_caches_on_grid_hackr_id"
    t.index ["system_type"], name: "index_grid_caches_on_system_type"
  end

  create_table "grid_den_invites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "den_id", null: false
    t.datetime "expires_at", null: false
    t.integer "guest_id", null: false
    t.integer "hackr_id", null: false
    t.datetime "revoked_at"
    t.datetime "updated_at", null: false
    t.index ["den_id"], name: "index_grid_den_invites_on_den_id"
    t.index ["expires_at"], name: "index_grid_den_invites_on_expires_at"
    t.index ["guest_id"], name: "index_grid_den_invites_on_guest_id"
    t.index ["hackr_id", "guest_id", "den_id"], name: "index_den_invites_unique", unique: true
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

  create_table "grid_faction_rep_links", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "source_faction_id", null: false
    t.integer "target_faction_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "weight", precision: 6, scale: 3, null: false
    t.index ["source_faction_id", "target_faction_id"], name: "index_faction_rep_links_unique", unique: true
    t.index ["source_faction_id"], name: "index_grid_faction_rep_links_on_source_faction_id"
    t.index ["target_faction_id"], name: "index_grid_faction_rep_links_on_target_faction_id"
  end

  create_table "grid_factions", force: :cascade do |t|
    t.integer "artist_id"
    t.string "color_scheme"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "kind", default: "collective", null: false
    t.string "name"
    t.integer "parent_id"
    t.integer "position", default: 0, null: false
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["kind"], name: "index_grid_factions_on_kind"
    t.index ["parent_id"], name: "index_grid_factions_on_parent_id"
    t.index ["slug"], name: "index_grid_factions_on_slug", unique: true
  end

  create_table "grid_hackr_achievements", force: :cascade do |t|
    t.datetime "awarded_at", null: false
    t.datetime "created_at", null: false
    t.integer "grid_achievement_id", null: false
    t.integer "grid_hackr_id", null: false
    t.datetime "updated_at", null: false
    t.index ["grid_achievement_id"], name: "index_grid_hackr_achievements_on_grid_achievement_id"
    t.index ["grid_hackr_id", "grid_achievement_id"], name: "index_hackr_achievements_unique", unique: true
    t.index ["grid_hackr_id"], name: "index_grid_hackr_achievements_on_grid_hackr_id"
  end

  create_table "grid_hackr_breach_logs", force: :cascade do |t|
    t.string "action_type", null: false
    t.datetime "created_at", null: false
    t.integer "grid_hackr_breach_id", null: false
    t.string "program_slug"
    t.json "result", default: {}, null: false
    t.integer "round", null: false
    t.string "target"
    t.index ["grid_hackr_breach_id", "round"], name: "index_breach_logs_on_breach_and_round"
    t.index ["grid_hackr_breach_id"], name: "index_grid_hackr_breach_logs_on_grid_hackr_breach_id"
  end

  create_table "grid_hackr_breaches", force: :cascade do |t|
    t.integer "actions_remaining", default: 1, null: false
    t.integer "actions_this_round", default: 1, null: false
    t.datetime "created_at", null: false
    t.integer "detection_level", default: 0, null: false
    t.datetime "ended_at"
    t.integer "grid_breach_encounter_id"
    t.integer "grid_breach_template_id", null: false
    t.integer "grid_hackr_id", null: false
    t.integer "inspiration", default: 0, null: false
    t.json "meta", default: {}, null: false
    t.integer "origin_room_id"
    t.integer "pnr_threshold", default: 75, null: false
    t.decimal "reward_multiplier", precision: 5, scale: 4, default: "1.0", null: false
    t.integer "round_number", default: 1, null: false
    t.datetime "started_at", null: false
    t.string "state", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["grid_breach_encounter_id"], name: "index_grid_hackr_breaches_on_grid_breach_encounter_id"
    t.index ["grid_breach_template_id"], name: "index_grid_hackr_breaches_on_grid_breach_template_id"
    t.index ["grid_hackr_id"], name: "index_grid_hackr_breaches_on_grid_hackr_id"
    t.index ["grid_hackr_id"], name: "index_hackr_breaches_one_active_per_hackr", unique: true, where: "state = 'active'"
    t.index ["state"], name: "index_grid_hackr_breaches_on_state"
  end

  create_table "grid_hackr_mission_objectives", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "grid_hackr_mission_id", null: false
    t.integer "grid_mission_objective_id", null: false
    t.integer "progress", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["grid_hackr_mission_id", "grid_mission_objective_id"], name: "index_hackr_mission_objs_unique", unique: true
    t.index ["grid_hackr_mission_id"], name: "index_hackr_mission_objs_on_hackr_mission"
    t.index ["grid_mission_objective_id"], name: "index_hackr_mission_objs_on_objective"
  end

  create_table "grid_hackr_missions", force: :cascade do |t|
    t.datetime "accepted_at", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.integer "grid_hackr_id", null: false
    t.integer "grid_mission_id", null: false
    t.string "status", default: "active", null: false
    t.integer "turn_in_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["grid_hackr_id", "grid_mission_id"], name: "index_hackr_missions_unique_active", unique: true, where: "status = 'active'"
    t.index ["grid_hackr_id", "status"], name: "index_hackr_missions_on_hackr_and_status"
    t.index ["grid_hackr_id"], name: "index_grid_hackr_missions_on_grid_hackr_id"
    t.index ["grid_mission_id"], name: "index_grid_hackr_missions_on_grid_mission_id"
  end

  create_table "grid_hackr_reputations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "grid_hackr_id", null: false
    t.bigint "subject_id", null: false
    t.string "subject_type", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 0, null: false
    t.index ["grid_hackr_id", "subject_type", "subject_id"], name: "index_hackr_reputations_unique", unique: true
    t.index ["grid_hackr_id"], name: "index_grid_hackr_reputations_on_grid_hackr_id"
    t.index ["subject_type", "subject_id"], name: "index_hackr_reputations_on_subject"
  end

  create_table "grid_hackr_track_plays", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "first_played_at", null: false
    t.integer "grid_hackr_id", null: false
    t.integer "play_count", default: 1, null: false
    t.integer "track_id", null: false
    t.datetime "updated_at", null: false
    t.index ["grid_hackr_id", "track_id"], name: "index_track_plays_unique", unique: true
    t.index ["grid_hackr_id"], name: "index_grid_hackr_track_plays_on_grid_hackr_id"
    t.index ["track_id"], name: "index_grid_hackr_track_plays_on_track_id"
  end

  create_table "grid_hackrs", force: :cascade do |t|
    t.string "api_token_digest"
    t.datetime "created_at", null: false
    t.integer "current_room_id"
    t.string "email"
    t.string "hackr_alias"
    t.datetime "last_activity_at"
    t.boolean "login_disabled", default: false, null: false
    t.json "otp_backup_code_digests"
    t.integer "otp_last_used_at"
    t.boolean "otp_required_for_login", default: false, null: false
    t.string "otp_secret"
    t.string "password_digest"
    t.string "registration_ip"
    t.string "role"
    t.boolean "service_account", default: false, null: false
    t.json "stats"
    t.datetime "updated_at", null: false
    t.integer "zone_entry_room_id"
    t.index ["api_token_digest"], name: "index_grid_hackrs_on_api_token_digest", unique: true
    t.index ["email"], name: "index_grid_hackrs_on_email", unique: true
    t.index ["hackr_alias"], name: "index_grid_hackrs_on_hackr_alias", unique: true
    t.index ["role"], name: "index_grid_hackrs_on_role"
  end

  create_table "grid_impound_records", force: :cascade do |t|
    t.integer "bribe_cost", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "grid_hackr_breach_id"
    t.integer "grid_hackr_id", null: false
    t.string "status", default: "impounded", null: false
    t.datetime "updated_at", null: false
    t.index ["grid_hackr_breach_id"], name: "index_grid_impound_records_on_grid_hackr_breach_id"
    t.index ["grid_hackr_id", "status"], name: "index_grid_impound_records_on_grid_hackr_id_and_status"
    t.index ["grid_hackr_id"], name: "index_grid_impound_records_on_grid_hackr_id"
  end

  create_table "grid_item_definitions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "item_type", null: false
    t.integer "max_stack"
    t.string "name", null: false
    t.json "properties", default: {}, null: false
    t.string "rarity", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 0, null: false
    t.index ["item_type"], name: "index_grid_item_definitions_on_item_type"
    t.index ["slug"], name: "index_grid_item_definitions_on_slug", unique: true
  end

  create_table "grid_items", force: :cascade do |t|
    t.integer "container_id"
    t.datetime "created_at", null: false
    t.integer "deck_id"
    t.text "description"
    t.string "equipped_slot"
    t.integer "grid_hackr_id"
    t.integer "grid_impound_record_id"
    t.integer "grid_item_definition_id", null: false
    t.integer "grid_mining_rig_id"
    t.string "item_type"
    t.string "name"
    t.json "properties"
    t.integer "quantity", default: 1, null: false
    t.string "rarity"
    t.integer "room_id"
    t.datetime "updated_at", null: false
    t.integer "value", default: 0, null: false
    t.index ["container_id"], name: "index_grid_items_on_container_id"
    t.index ["deck_id"], name: "index_grid_items_on_deck_id"
    t.index ["grid_hackr_id", "equipped_slot"], name: "index_grid_items_on_hackr_equipped_slot_unique", unique: true, where: "equipped_slot IS NOT NULL"
    t.index ["grid_hackr_id"], name: "index_grid_items_on_grid_hackr_id"
    t.index ["grid_impound_record_id"], name: "index_grid_items_on_grid_impound_record_id"
    t.index ["grid_item_definition_id"], name: "index_grid_items_on_grid_item_definition_id"
    t.index ["grid_mining_rig_id"], name: "index_grid_items_on_grid_mining_rig_id"
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

  create_table "grid_mining_rigs", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "grid_hackr_id", null: false
    t.datetime "last_tick_at"
    t.datetime "updated_at", null: false
    t.index ["grid_hackr_id"], name: "index_grid_mining_rigs_on_grid_hackr_id", unique: true
  end

  create_table "grid_mission_arcs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.boolean "published", default: false, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_grid_mission_arcs_on_slug", unique: true
  end

  create_table "grid_mission_objectives", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "grid_mission_id", null: false
    t.string "label", null: false
    t.string "objective_type", null: false
    t.integer "position", default: 0, null: false
    t.integer "target_count", default: 1, null: false
    t.string "target_slug"
    t.datetime "updated_at", null: false
    t.index ["grid_mission_id", "position"], name: "index_mission_objectives_on_mission_and_position"
    t.index ["grid_mission_id"], name: "index_grid_mission_objectives_on_grid_mission_id"
  end

  create_table "grid_mission_rewards", force: :cascade do |t|
    t.integer "amount", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "grid_mission_id", null: false
    t.integer "position", default: 0, null: false
    t.integer "quantity", default: 1, null: false
    t.string "reward_type", null: false
    t.string "target_slug"
    t.datetime "updated_at", null: false
    t.index ["grid_mission_id"], name: "index_grid_mission_rewards_on_grid_mission_id"
  end

  create_table "grid_missions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.json "dialogue_path"
    t.integer "giver_mob_id"
    t.integer "grid_mission_arc_id"
    t.integer "min_clearance", default: 0, null: false
    t.integer "min_rep_faction_id"
    t.integer "min_rep_value", default: 0, null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.integer "prereq_mission_id"
    t.boolean "published", default: false, null: false
    t.boolean "repeatable", default: false, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["giver_mob_id"], name: "index_grid_missions_on_giver_mob_id"
    t.index ["grid_mission_arc_id"], name: "index_grid_missions_on_grid_mission_arc_id"
    t.index ["min_rep_faction_id"], name: "index_grid_missions_on_min_rep_faction_id"
    t.index ["prereq_mission_id"], name: "index_grid_missions_on_prereq_mission_id"
    t.index ["slug"], name: "index_grid_missions_on_slug", unique: true
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
    t.json "vendor_config"
  end

  create_table "grid_regions", force: :cascade do |t|
    t.integer "containment_room_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "facility_bribe_exit_room_id"
    t.integer "facility_exit_room_id"
    t.integer "hospital_room_id"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["containment_room_id"], name: "index_grid_regions_on_containment_room_id"
    t.index ["facility_bribe_exit_room_id"], name: "index_grid_regions_on_facility_bribe_exit_room_id"
    t.index ["facility_exit_room_id"], name: "index_grid_regions_on_facility_exit_room_id"
    t.index ["hospital_room_id"], name: "index_grid_regions_on_hospital_room_id"
    t.index ["slug"], name: "index_grid_regions_on_slug", unique: true
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

  create_table "grid_reputation_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "delta", null: false
    t.integer "grid_hackr_id", null: false
    t.text "note"
    t.string "reason"
    t.bigint "source_id"
    t.string "source_type"
    t.bigint "subject_id", null: false
    t.string "subject_type", null: false
    t.integer "value_after", null: false
    t.index ["grid_hackr_id", "created_at"], name: "index_rep_events_on_hackr_and_time", order: { created_at: :desc }
    t.index ["grid_hackr_id"], name: "index_grid_reputation_events_on_grid_hackr_id"
    t.index ["source_type", "source_id"], name: "index_rep_events_on_source"
    t.index ["subject_type", "subject_id", "created_at"], name: "index_rep_events_on_subject_and_time", order: { created_at: :desc }
  end

  create_table "grid_rooms", force: :cascade do |t|
    t.integer "ambient_playlist_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "grid_zone_id", null: false
    t.boolean "locked", default: false, null: false
    t.integer "map_x"
    t.integer "map_y"
    t.integer "map_z", default: 0, null: false
    t.integer "min_clearance", default: 0, null: false
    t.string "name"
    t.integer "owner_id"
    t.string "room_type"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["ambient_playlist_id"], name: "index_grid_rooms_on_ambient_playlist_id"
    t.index ["grid_zone_id"], name: "index_grid_rooms_on_grid_zone_id"
    t.index ["owner_id"], name: "index_grid_rooms_on_owner_id", unique: true
    t.index ["slug"], name: "index_grid_rooms_on_slug", unique: true
  end

  create_table "grid_salvage_yields", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "output_definition_id", null: false
    t.integer "position", default: 0, null: false
    t.integer "quantity", default: 1, null: false
    t.integer "source_definition_id", null: false
    t.datetime "updated_at", null: false
    t.index ["output_definition_id"], name: "index_grid_salvage_yields_on_output_definition_id"
    t.index ["source_definition_id", "output_definition_id"], name: "index_grid_salvage_yields_unique", unique: true
    t.index ["source_definition_id"], name: "index_grid_salvage_yields_on_source_definition_id"
  end

  create_table "grid_schematic_ingredients", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "grid_schematic_id", null: false
    t.integer "input_definition_id", null: false
    t.integer "position", default: 0, null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["grid_schematic_id", "input_definition_id"], name: "index_grid_schematic_ingredients_unique", unique: true
    t.index ["grid_schematic_id"], name: "index_grid_schematic_ingredients_on_grid_schematic_id"
    t.index ["input_definition_id"], name: "index_grid_schematic_ingredients_on_input_definition_id"
  end

  create_table "grid_schematics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "output_definition_id", null: false
    t.integer "output_quantity", default: 1, null: false
    t.integer "position", default: 0, null: false
    t.boolean "published", default: false, null: false
    t.string "required_achievement_slug"
    t.integer "required_clearance", default: 0, null: false
    t.string "required_mission_slug"
    t.string "required_room_type"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.integer "xp_reward", default: 0, null: false
    t.index ["output_definition_id"], name: "index_grid_schematics_on_output_definition_id"
    t.index ["slug"], name: "index_grid_schematics_on_slug", unique: true
  end

  create_table "grid_shop_listings", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "base_price", null: false
    t.datetime "created_at", null: false
    t.integer "grid_item_definition_id", null: false
    t.integer "grid_mob_id", null: false
    t.integer "max_stock"
    t.integer "min_clearance", default: 0, null: false
    t.datetime "next_restock_at"
    t.integer "restock_amount", default: 1, null: false
    t.integer "restock_interval_hours", default: 24, null: false
    t.boolean "rotation_pool", default: false, null: false
    t.integer "sell_price", null: false
    t.integer "stock"
    t.datetime "updated_at", null: false
    t.index ["grid_item_definition_id"], name: "index_grid_shop_listings_on_grid_item_definition_id"
    t.index ["grid_mob_id", "active"], name: "index_grid_shop_listings_on_grid_mob_id_and_active"
    t.index ["grid_mob_id"], name: "index_grid_shop_listings_on_grid_mob_id"
    t.index ["next_restock_at"], name: "index_grid_shop_listings_on_next_restock_at"
  end

  create_table "grid_shop_transactions", force: :cascade do |t|
    t.integer "burn_amount", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "grid_hackr_id"
    t.integer "grid_mob_id"
    t.integer "grid_shop_listing_id"
    t.integer "price_paid", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "recycle_amount", default: 0, null: false
    t.string "transaction_type", null: false
    t.index ["grid_hackr_id", "created_at"], name: "index_grid_shop_transactions_on_grid_hackr_id_and_created_at"
    t.index ["grid_hackr_id"], name: "index_grid_shop_transactions_on_grid_hackr_id"
    t.index ["grid_mob_id"], name: "index_grid_shop_transactions_on_grid_mob_id"
    t.index ["grid_shop_listing_id"], name: "index_grid_shop_transactions_on_grid_shop_listing_id"
  end

  create_table "grid_transactions", force: :cascade do |t|
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.integer "from_cache_id", null: false
    t.string "memo"
    t.string "previous_tx_hash"
    t.integer "to_cache_id", null: false
    t.string "tx_hash", null: false
    t.string "tx_type", null: false
    t.index ["created_at"], name: "index_grid_transactions_on_created_at"
    t.index ["from_cache_id"], name: "index_grid_transactions_on_from_cache_id"
    t.index ["to_cache_id"], name: "index_grid_transactions_on_to_cache_id"
    t.index ["tx_hash"], name: "index_grid_transactions_on_tx_hash", unique: true
    t.index ["tx_type"], name: "index_grid_transactions_on_tx_type"
  end

  create_table "grid_uplink_presences", force: :cascade do |t|
    t.integer "chat_channel_id", null: false
    t.integer "grid_hackr_id", null: false
    t.datetime "last_seen_at", null: false
    t.index ["grid_hackr_id", "chat_channel_id"], name: "index_grid_uplink_presences_unique", unique: true
    t.index ["last_seen_at"], name: "index_grid_uplink_presences_on_last_seen_at"
  end

  create_table "grid_verification_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.integer "grid_hackr_id", null: false
    t.string "ip_address"
    t.json "metadata", default: {}
    t.string "purpose", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.index ["grid_hackr_id", "purpose"], name: "index_grid_verification_tokens_on_grid_hackr_id_and_purpose"
    t.index ["grid_hackr_id"], name: "index_grid_verification_tokens_on_grid_hackr_id"
    t.index ["token"], name: "index_grid_verification_tokens_on_token", unique: true
  end

  create_table "grid_zones", force: :cascade do |t|
    t.integer "ambient_playlist_id"
    t.string "color_scheme"
    t.datetime "created_at", null: false
    t.integer "danger_level", default: 0, null: false
    t.text "description"
    t.integer "grid_faction_id"
    t.integer "grid_region_id"
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.string "zone_type"
    t.index ["ambient_playlist_id"], name: "index_grid_zones_on_ambient_playlist_id"
    t.index ["grid_region_id"], name: "index_grid_zones_on_grid_region_id"
  end

  create_table "hackr_log_reads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "grid_hackr_id", null: false
    t.integer "hackr_log_id", null: false
    t.datetime "read_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grid_hackr_id", "hackr_log_id"], name: "index_hackr_log_reads_unique", unique: true
    t.index ["grid_hackr_id"], name: "index_hackr_log_reads_on_grid_hackr_id"
    t.index ["hackr_log_id"], name: "index_hackr_log_reads_on_hackr_log_id"
  end

  create_table "hackr_logs", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "grid_hackr_id", null: false
    t.boolean "published", default: false, null: false
    t.datetime "published_at"
    t.string "slug", null: false
    t.string "timeline", default: "2120s", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["grid_hackr_id"], name: "index_hackr_logs_on_grid_hackr_id"
    t.index ["slug"], name: "index_hackr_logs_on_slug", unique: true
    t.index ["timeline"], name: "index_hackr_logs_on_timeline"
  end

  create_table "hackr_page_views", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "grid_hackr_id", null: false
    t.string "page_type", null: false
    t.integer "resource_id", null: false
    t.datetime "updated_at", null: false
    t.datetime "viewed_at", null: false
    t.index ["grid_hackr_id", "page_type", "resource_id"], name: "index_hackr_page_views_unique", unique: true
    t.index ["grid_hackr_id", "page_type"], name: "index_hackr_page_views_hackr_type"
    t.index ["grid_hackr_id"], name: "index_hackr_page_views_on_grid_hackr_id"
  end

  create_table "hackr_radio_tunes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "grid_hackr_id", null: false
    t.integer "radio_station_id", null: false
    t.datetime "tuned_at", null: false
    t.datetime "updated_at", null: false
    t.index ["grid_hackr_id", "radio_station_id"], name: "index_hackr_radio_tunes_unique", unique: true
    t.index ["grid_hackr_id"], name: "index_hackr_radio_tunes_on_grid_hackr_id"
    t.index ["radio_station_id"], name: "index_hackr_radio_tunes_on_radio_station_id"
  end

  create_table "hackr_streams", force: :cascade do |t|
    t.integer "artist_id", null: false
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.boolean "is_live", default: false, null: false
    t.string "live_url"
    t.datetime "started_at"
    t.string "title"
    t.string "track_slug"
    t.datetime "updated_at", null: false
    t.string "vod_url"
    t.index ["artist_id"], name: "index_hackr_streams_on_artist_id"
  end

  create_table "hackr_vod_watches", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "grid_hackr_id", null: false
    t.integer "hackr_stream_id", null: false
    t.datetime "updated_at", null: false
    t.datetime "watched_at", null: false
    t.index ["grid_hackr_id", "hackr_stream_id"], name: "index_hackr_vod_watches_unique", unique: true
    t.index ["grid_hackr_id"], name: "index_hackr_vod_watches_on_grid_hackr_id"
    t.index ["hackr_stream_id"], name: "index_hackr_vod_watches_on_hackr_stream_id"
  end

  create_table "handbook_articles", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "difficulty"
    t.integer "handbook_section_id", null: false
    t.string "kind", default: "reference", null: false
    t.json "metadata", default: {}
    t.integer "position", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.string "slug", null: false
    t.text "summary"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["handbook_section_id", "position"], name: "index_handbook_articles_on_handbook_section_id_and_position"
    t.index ["handbook_section_id"], name: "index_handbook_articles_on_handbook_section_id"
    t.index ["kind"], name: "index_handbook_articles_on_kind"
    t.index ["published"], name: "index_handbook_articles_on_published"
    t.index ["slug"], name: "index_handbook_articles_on_slug", unique: true
  end

  create_table "handbook_sections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "icon"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.boolean "published", default: true, null: false
    t.string "slug", null: false
    t.text "summary"
    t.datetime "updated_at", null: false
    t.index ["published", "position"], name: "index_handbook_sections_on_published_and_position"
    t.index ["published"], name: "index_handbook_sections_on_published"
    t.index ["slug"], name: "index_handbook_sections_on_slug", unique: true
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
    t.boolean "hidden", default: false, null: false
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

  create_table "releases", force: :cascade do |t|
    t.integer "artist_id", null: false
    t.string "catalog_number"
    t.string "classification"
    t.boolean "coming_soon", default: false, null: false
    t.datetime "created_at", null: false
    t.text "credits"
    t.text "description"
    t.string "label"
    t.string "media_format"
    t.string "name", null: false
    t.text "notes"
    t.date "release_date"
    t.string "release_type"
    t.string "slug", null: false
    t.text "streaming_links"
    t.datetime "updated_at", null: false
    t.index ["artist_id", "slug"], name: "index_releases_on_artist_id_and_slug", unique: true
    t.index ["artist_id"], name: "index_releases_on_artist_id"
  end

  create_table "sent_emails", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "emailable_id"
    t.string "emailable_type"
    t.string "from", null: false
    t.text "html_body"
    t.string "mailer_action", null: false
    t.string "mailer_class", null: false
    t.string "subject", null: false
    t.text "text_body"
    t.string "to", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_sent_emails_on_created_at"
    t.index ["emailable_type", "emailable_id"], name: "index_sent_emails_on_emailable"
  end

  create_table "terminal_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.string "handler"
    t.string "input"
    t.json "metadata"
    t.integer "terminal_session_id", null: false
    t.index ["created_at"], name: "index_terminal_events_on_created_at"
    t.index ["event_type"], name: "index_terminal_events_on_event_type"
    t.index ["terminal_session_id", "created_at"], name: "index_terminal_events_on_terminal_session_id_and_created_at"
    t.index ["terminal_session_id"], name: "index_terminal_events_on_terminal_session_id"
  end

  create_table "terminal_sessions", force: :cascade do |t|
    t.datetime "connected_at", null: false
    t.string "disconnect_reason"
    t.datetime "disconnected_at"
    t.integer "duration_seconds"
    t.integer "grid_hackr_id"
    t.string "ip_address"
    t.index ["connected_at"], name: "index_terminal_sessions_on_connected_at"
    t.index ["grid_hackr_id"], name: "index_terminal_sessions_on_grid_hackr_id"
    t.index ["ip_address"], name: "index_terminal_sessions_on_ip_address"
  end

  create_table "tracks", force: :cascade do |t|
    t.integer "artist_id", null: false
    t.string "cover_image"
    t.datetime "created_at", null: false
    t.string "duration"
    t.boolean "featured", default: false
    t.text "lyrics"
    t.date "release_date"
    t.integer "release_id", null: false
    t.boolean "show_in_pulse_vault", default: true, null: false
    t.string "slug"
    t.text "streaming_links"
    t.string "title"
    t.integer "track_number"
    t.datetime "updated_at", null: false
    t.text "videos"
    t.index ["artist_id", "slug"], name: "index_tracks_on_artist_id_and_slug", unique: true
    t.index ["artist_id"], name: "index_tracks_on_artist_id"
    t.index ["featured"], name: "index_tracks_on_featured"
    t.index ["release_date"], name: "index_tracks_on_release_date"
    t.index ["release_id"], name: "index_tracks_on_release_id"
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

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.text "object", limit: 1073741823
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
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
  add_foreign_key "chat_messages", "chat_channels"
  add_foreign_key "chat_messages", "grid_hackrs"
  add_foreign_key "chat_messages", "hackr_streams"
  add_foreign_key "codex_entry_reads", "codex_entries"
  add_foreign_key "codex_entry_reads", "grid_hackrs"
  add_foreign_key "echoes", "grid_hackrs"
  add_foreign_key "echoes", "pulses"
  add_foreign_key "feature_grants", "grid_hackrs"
  add_foreign_key "grid_breach_encounters", "grid_breach_templates", on_delete: :restrict
  add_foreign_key "grid_breach_encounters", "grid_rooms", on_delete: :cascade
  add_foreign_key "grid_breach_protocols", "grid_hackr_breaches", on_delete: :cascade
  add_foreign_key "grid_den_invites", "grid_hackrs", column: "guest_id"
  add_foreign_key "grid_den_invites", "grid_hackrs", column: "hackr_id"
  add_foreign_key "grid_den_invites", "grid_rooms", column: "den_id"
  add_foreign_key "grid_faction_rep_links", "grid_factions", column: "source_faction_id"
  add_foreign_key "grid_faction_rep_links", "grid_factions", column: "target_faction_id"
  add_foreign_key "grid_factions", "grid_factions", column: "parent_id"
  add_foreign_key "grid_hackr_achievements", "grid_achievements"
  add_foreign_key "grid_hackr_achievements", "grid_hackrs"
  add_foreign_key "grid_hackr_breach_logs", "grid_hackr_breaches", on_delete: :cascade
  add_foreign_key "grid_hackr_breaches", "grid_breach_encounters", on_delete: :nullify
  add_foreign_key "grid_hackr_breaches", "grid_breach_templates", on_delete: :restrict
  add_foreign_key "grid_hackr_breaches", "grid_hackrs", on_delete: :cascade
  add_foreign_key "grid_hackr_breaches", "grid_rooms", column: "origin_room_id", on_delete: :nullify
  add_foreign_key "grid_hackr_mission_objectives", "grid_hackr_missions", on_delete: :cascade
  add_foreign_key "grid_hackr_mission_objectives", "grid_mission_objectives", on_delete: :restrict
  add_foreign_key "grid_hackr_missions", "grid_hackrs", on_delete: :cascade
  add_foreign_key "grid_hackr_missions", "grid_missions", on_delete: :cascade
  add_foreign_key "grid_hackr_reputations", "grid_hackrs"
  add_foreign_key "grid_hackr_track_plays", "grid_hackrs"
  add_foreign_key "grid_hackr_track_plays", "tracks"
  add_foreign_key "grid_hackrs", "grid_rooms", column: "zone_entry_room_id", on_delete: :nullify
  add_foreign_key "grid_impound_records", "grid_hackr_breaches", on_delete: :nullify
  add_foreign_key "grid_impound_records", "grid_hackrs", on_delete: :cascade
  add_foreign_key "grid_items", "grid_impound_records", on_delete: :nullify
  add_foreign_key "grid_items", "grid_item_definitions"
  add_foreign_key "grid_items", "grid_items", column: "container_id"
  add_foreign_key "grid_items", "grid_items", column: "deck_id", on_delete: :nullify
  add_foreign_key "grid_mission_objectives", "grid_missions", on_delete: :cascade
  add_foreign_key "grid_mission_rewards", "grid_missions", on_delete: :cascade
  add_foreign_key "grid_missions", "grid_factions", column: "min_rep_faction_id", on_delete: :nullify
  add_foreign_key "grid_missions", "grid_mission_arcs", on_delete: :nullify
  add_foreign_key "grid_missions", "grid_missions", column: "prereq_mission_id", on_delete: :nullify
  add_foreign_key "grid_missions", "grid_mobs", column: "giver_mob_id", on_delete: :nullify
  add_foreign_key "grid_regions", "grid_rooms", column: "containment_room_id", on_delete: :nullify
  add_foreign_key "grid_regions", "grid_rooms", column: "facility_bribe_exit_room_id", on_delete: :nullify
  add_foreign_key "grid_regions", "grid_rooms", column: "facility_exit_room_id", on_delete: :nullify
  add_foreign_key "grid_regions", "grid_rooms", column: "hospital_room_id", on_delete: :nullify
  add_foreign_key "grid_reputation_events", "grid_hackrs"
  add_foreign_key "grid_rooms", "grid_hackrs", column: "owner_id"
  add_foreign_key "grid_rooms", "zone_playlists", column: "ambient_playlist_id"
  add_foreign_key "grid_salvage_yields", "grid_item_definitions", column: "output_definition_id"
  add_foreign_key "grid_salvage_yields", "grid_item_definitions", column: "source_definition_id"
  add_foreign_key "grid_schematic_ingredients", "grid_item_definitions", column: "input_definition_id"
  add_foreign_key "grid_schematic_ingredients", "grid_schematics"
  add_foreign_key "grid_schematics", "grid_item_definitions", column: "output_definition_id"
  add_foreign_key "grid_shop_listings", "grid_item_definitions"
  add_foreign_key "grid_shop_listings", "grid_mobs"
  add_foreign_key "grid_verification_tokens", "grid_hackrs"
  add_foreign_key "grid_zones", "grid_regions"
  add_foreign_key "grid_zones", "zone_playlists", column: "ambient_playlist_id"
  add_foreign_key "hackr_log_reads", "grid_hackrs"
  add_foreign_key "hackr_log_reads", "hackr_logs"
  add_foreign_key "hackr_logs", "grid_hackrs"
  add_foreign_key "hackr_page_views", "grid_hackrs"
  add_foreign_key "hackr_radio_tunes", "grid_hackrs"
  add_foreign_key "hackr_radio_tunes", "radio_stations"
  add_foreign_key "hackr_streams", "artists"
  add_foreign_key "hackr_vod_watches", "grid_hackrs"
  add_foreign_key "hackr_vod_watches", "hackr_streams"
  add_foreign_key "handbook_articles", "handbook_sections"
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
  add_foreign_key "releases", "artists"
  add_foreign_key "terminal_events", "terminal_sessions"
  add_foreign_key "terminal_sessions", "grid_hackrs"
  add_foreign_key "tracks", "artists"
  add_foreign_key "tracks", "releases"
  add_foreign_key "user_punishments", "grid_hackrs"
  add_foreign_key "user_punishments", "grid_hackrs", column: "issued_by_id"
  add_foreign_key "zone_playlist_tracks", "tracks"
  add_foreign_key "zone_playlist_tracks", "zone_playlists"
end
