Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Root route (SPA)
  root "pages#spa_root"

  # XERAEN vidz redirect to thecyberpulse
  get "xeraen/vidz", to: redirect("/thecyberpulse/vidz")
  get "xeraen/vidz/:id", to: redirect("/thecyberpulse/vidz/%{id}")

  # Artist routes - SPA (consolidated per-artist pattern)
  # Each artist gets: profile, releases, track detail, vidz
  %w[thecyberpulse xeraen system-rot wavelength-zero voiceprint temporal-blue-drift
    injection-vector cipher-protocol blitzbeam apex-overdrive ethereality
    neon-hearts offline heartbreak-havoc the-pulse-grid].each do |artist_slug|
    scope artist_slug do
      get "/", to: "pages#spa_root"
      get "bio", to: "pages#spa_root"
      get "releases", to: "pages#spa_root"
      get "releases/:id", to: "pages#spa_root"
      get "trackz/:id", to: "pages#spa_root"
      get "vidz", to: "pages#spa_root"
      get "vidz/:id", to: "pages#spa_root"
    end
  end

  # Sector X routes - SPA
  get "sector/x", to: "pages#spa_root", as: :sector_x

  # Legacy routes for backward compatibility (redirects to new paths)
  get "trackz", to: "tracks#legacy_redirect", as: :legacy_tracks
  get "trackz/:id", to: "tracks#legacy_redirect_show", as: :legacy_track

  # THE PULSE GRID routes (SPA)
  scope "grid" do
    get "/", to: "pages#spa_root", as: :grid
    get "login", to: "pages#spa_root", as: :grid_login
    get "register", to: "pages#spa_root", as: :grid_register
    get "verify/:token", to: "pages#spa_root", as: :grid_verify
    get "forgot_password", to: "pages#spa_root", as: :grid_forgot_password
    get "identity", to: "pages#spa_root", as: :grid_identity
    get "identity/two-factor", to: "pages#spa_root", as: :grid_two_factor
    get "reset_password/:token", to: "pages#spa_root", as: :grid_password_reset
    get "confirm_email_change/:token", to: "pages#spa_root", as: :grid_confirm_email_change
    get "1337", to: "pages#spa_root", as: :grid_tactical
  end

  # Vault (promoted from /fm/pulse-vault)
  get "vault", to: "pages#spa_root", as: :vault
  get "fm/pulse-vault", to: redirect("/vault")
  get "pulse-vault", to: redirect("/vault")

  # hackr.fm routes - SPA
  scope "fm" do
    get "/", to: "pages#spa_root", as: :fm
    get "releases", to: "pages#spa_root", as: :fm_releases
    get "radio", to: "pages#spa_root", as: :fm_radio
    get "playlists", to: "pages#spa_root", as: :fm_playlists
    get "playlists/:id", to: "pages#spa_root", as: :fm_playlist
  end

  # Fracture Network - SPA
  scope "f" do
    get "net", to: "pages#spa_root", as: :f_net
  end
  get "fnet", to: redirect("/f/net")

  # Shared playlist - public (SPA)
  get "shared/:token", to: "pages#spa_root", as: :shared_playlist

  # HackrLogs (blog) routes - SPA
  scope "logs" do
    get "/", to: "pages#spa_root", as: :hackr_logs
    get ":id", to: "pages#spa_root", as: :hackr_log
  end

  # Code browser routes - SPA
  scope "code" do
    get "/", to: "pages#spa_root", as: :code
    get ":repo", to: "pages#spa_root", as: :code_repo
    get ":repo/tree/*path", to: "pages#spa_root", as: :code_tree, format: false
    get ":repo/blob/*path", to: "pages#spa_root", as: :code_blob, format: false
  end

  # Timeline route - SPA
  get "timeline", to: "pages#spa_root", as: :timeline

  # Achievements (login-gated SPA)
  get "achievements", to: "pages#spa_root", as: :achievements

  # Missions (login-gated SPA). Per-mission detail renders inline in
  # the MissionsPage card grid — no dedicated per-slug React route, so
  # we don't expose `/missions/:slug` as a Rails SPA path either.
  get "missions", to: "pages#spa_root", as: :missions
  get "schematics", to: "pages#spa_root", as: :schematics
  get "loadout", to: "pages#spa_root", as: :loadout
  get "gear", to: redirect("/loadout")
  get "deck", to: "pages#spa_root", as: :deck_page
  get "transit", to: "pages#spa_root", as: :transit_page

  # Codex (wiki) routes - SPA
  scope "codex" do
    get "/", to: "pages#spa_root", as: :codex
    get ":slug", to: "pages#spa_root", as: :codex_entry
  end

  # Handbook (practical docs for GridHackr users) - SPA
  scope "handbook" do
    get "/", to: "pages#spa_root", as: :handbook
    get ":slug", to: "pages#spa_root", as: :handbook_article
  end

  # PulseWire routes - SPA
  scope "wire" do
    get "/", to: "pages#spa_root", as: :wire
    get "pulse/:id", to: "pages#spa_root", as: :wire_pulse
    get ":username", to: "pages#spa_root", as: :wire_user
  end

  # Uplink routes - SPA
  get "uplink", to: "pages#spa_root", as: :uplink
  get "uplink/popout", to: "pages#spa_root", as: :uplink_popout

  # Terminal SSH access credentials page
  get "terminal", to: "terminal#index", as: :terminal

  # API routes (for SPA)
  namespace :api, defaults: {format: :json} do
    get "settings", to: "settings#index"

    resources :artists, only: %i[index show] do
      resources :tracks, only: [:index]
      member do
        post :bio_viewed
        post :release_index_viewed
      end
    end
    resources :tracks, only: %i[index show] do
      member do
        post :play_credit
      end
    end
    resources :releases, only: %i[index show] do
      get :latest, on: :collection
      get :coming_soon, on: :collection
      member do
        post :viewed
      end
    end
    get "codex/mappings", to: "codex#mappings"
    get "codex", to: "codex#index"
    get "codex/:slug", to: "codex#show"
    post "codex/:slug/read", to: "codex#mark_read"

    get "handbook/mappings", to: "handbook#mappings"
    get "handbook/recent", to: "handbook#recent"
    get "handbook", to: "handbook#index"
    get "handbook/:slug", to: "handbook#show"
    get "radio_stations", to: "radio#index"
    get "radio_stations/:id/playlists", to: "radio#station_playlists"
    post "radio_stations/:id/tune_in", to: "radio#tune_in"
    get "hackr_stream", to: "hackr_streams#show"
    get "artists/:artist_slug/vods", to: "hackr_streams#index"
    get "artists/:artist_slug/vods/:id", to: "hackr_streams#vod_show"
    post "artists/:artist_slug/vods/:id/watch", to: "hackr_streams#watch"

    # Grid API routes
    get "grid/current_hackr", to: "grid#current_hackr_info"
    get "grid/achievements", to: "grid#achievements_index"
    get "grid/missions", to: "grid#missions_index"
    get "grid/schematics", to: "grid#schematics_index"
    get "grid/loadout", to: "grid#loadout_index"
    get "grid/deck", to: "grid#deck_index"
    get "grid/inventory", to: "grid#inventory_index"
    get "grid/reputation", to: "grid#reputation_index"
    get "grid/cred", to: "grid#cred_index"
    get "grid/shop", to: "grid#shop_index"
    get "grid/npc", to: "grid#npc_index"
    get "grid/transit", to: "grid#transit_index"
    post "grid/login", to: "grid#login"
    post "grid/register", to: "grid#register"
    get "grid/verify/:token", to: "grid#verify_token"
    post "grid/complete_registration", to: "grid#complete_registration"
    delete "grid/disconnect", to: "grid#disconnect"
    post "grid/command", to: "grid#command"
    post "grid/debit", to: "grid#debit"
    post "grid/forgot_password", to: "grid#forgot_password"
    post "grid/request_password_reset", to: "grid#request_password_reset"
    post "grid/reset_password", to: "grid#reset_password"
    post "grid/request_email_change", to: "grid#request_email_change"
    post "grid/confirm_email_change", to: "grid#confirm_email_change"
    get "grid/zone_map", to: "grid#zone_map"

    # TOTP two-factor authentication
    get "totp/status", to: "totp#status"
    post "totp/setup", to: "totp#setup"
    post "totp/enable", to: "totp#enable"
    post "totp/verify", to: "totp#verify"
    delete "totp/disable", to: "totp#disable"
    post "totp/regenerate_backup_codes", to: "totp#regenerate_backup_codes"
    post "totp/admin_reset", to: "totp#admin_reset"

    # Code browser API routes
    get "code", to: "code#index"
    get "code/:repo", to: "code#show"
    get "code/:repo/tree/*path", to: "code#tree", format: false
    get "code/:repo/blob/*path", to: "code#blob", format: false

    # Hackr Logs API routes
    resources :logs, only: %i[index show]
    post "logs/:id/read", to: "logs#mark_read"

    # Playlists API routes
    resources :playlists do
      post "reorder", on: :member
      resources :tracks, controller: "playlist_tracks", only: %i[create destroy]
    end
    get "shared_playlists/:share_token", to: "shared_playlists#show"

    # PulseWire API routes
    resources :pulses, only: %i[index show create destroy] do
      post "signal_drop", on: :member
      post "echo", to: "echoes#create"
      get "echoes", to: "echoes#index"
    end

    # Overlay API routes
    post "overlay/now-playing", to: "overlay#set_now_playing"

    # Uplink API routes
    namespace :uplink do
      resources :channels, only: %i[index show], param: :slug do
        resources :packets, only: %i[index create], param: :id
      end
      delete "packets/:id", to: "packets#destroy", as: :packet

      # Moderation
      post "users/:id/squelch", to: "moderation#squelch", as: :squelch_user
      post "users/:id/blackout", to: "moderation#blackout", as: :blackout_user
      delete "users/:id/punishment", to: "moderation#lift_punishment", as: :lift_punishment
      get "moderation_log", to: "moderation#moderation_log", as: :moderation_log
    end

    # Admin API routes (bearer token auth)
    namespace :admin do
      # Meta
      get "capabilities", to: "meta#capabilities"
      get "rate_limit", to: "meta#rate_limit"
      get "stats", to: "meta#stats"

      # Streams
      get "streams/status", to: "streams#status"
      post "streams/go_live", to: "streams#go_live"
      post "streams/end_stream", to: "streams#end_stream"

      # HackrLogs
      get "hackr_logs", to: "hackr_logs#index"
      post "hackr_logs", to: "hackr_logs#create"
      patch "hackr_logs/:slug", to: "hackr_logs#update"

      # Pulses
      post "pulses", to: "pulses#create"
      post "pulses/:pulse_id/echo", to: "pulses#echo"
      post "pulses/splice", to: "pulses#splice"

      # Uplink
      post "uplink/send_packet", to: "uplink#send_packet"

      # Code sync
      post "code/sync", to: "code#sync"
    end
  end

  # Admin routes (accessible at /root)
  # NOTE: Most resources are read-only (managed via YAML files)
  # Edit YAML files in data/ directory and run: rails data:load
  namespace :admin, path: "root" do
    root "dashboard#index"

    # Catalog resources (full CRUD)
    resources :artists do
      member do
        get :history
      end
    end
    resources :releases do
      member do
        delete :purge_cover, to: "releases#purge_cover"
        get :history
      end
    end
    resources :tracks do
      member do
        delete :purge_audio, to: "tracks#purge_audio"
        get :history
      end
    end

    # Content resources (full CRUD)
    resources :codex_entries do
      member do
        get :history
      end
    end
    resources :hackr_logs do
      member do
        get :history
      end
    end

    # System resources (read-only)
    resources :radio_stations, only: %i[index show]
    resources :zone_playlists, only: %i[index show]

    # World Export (download DB → YAML archive)
    get "grid_world_export", to: "grid_world_export#download", as: :grid_world_export

    # Map Editor (zone-scoped visual editor)
    scope "grid_map_editor", as: :grid_map_editor do
      get ":zone_id", to: "grid_map_editor#show", as: :show
      get ":zone_id/data", to: "grid_map_editor#data", as: :data
      post "rooms", to: "grid_map_editor#create_room", as: :create_room
      patch "rooms/:id", to: "grid_map_editor#update_room", as: :update_room
      delete "rooms/:id", to: "grid_map_editor#destroy_room", as: :destroy_room
      post "exits", to: "grid_map_editor#create_exit", as: :create_exit
      patch "exits/:id", to: "grid_map_editor#update_exit", as: :update_exit
      delete "exits/:id", to: "grid_map_editor#destroy_exit", as: :destroy_exit
      post "mobs", to: "grid_map_editor#create_mob", as: :create_mob
      patch "mobs/:id", to: "grid_map_editor#update_mob", as: :update_mob
      delete "mobs/:id", to: "grid_map_editor#remove_mob", as: :remove_mob
      post "encounters", to: "grid_map_editor#create_encounter", as: :create_encounter
      delete "encounters/:id", to: "grid_map_editor#destroy_encounter", as: :destroy_encounter
      # Region scope
      get "region/:region_id", to: "grid_map_editor#region_show", as: :region_show
      get "region/:region_id/data", to: "grid_map_editor#region_data", as: :region_data
    end

    # World resources (full CRUD)
    resources :grid_regions do
      member do
        get :history
      end
    end
    resources :grid_zones do
      member do
        get :history
      end
    end
    resources :grid_rooms do
      member do
        get :history
      end
    end
    resources :grid_mobs do
      member do
        get :history
        post :add_listing
        delete :remove_listing
      end
    end
    resources :grid_exits do
      member do
        get :history
      end
    end

    # Grid management (still functional - runtime operations)
    get "grid", to: "grid#index", as: :grid
    post "grid/broadcast", to: "grid#broadcast", as: :grid_broadcast
    post "grid/hackrs/:hackr_id/reset_totp", to: "grid#reset_totp", as: :grid_reset_totp
    post "grid/hackrs/:hackr_id/disable_login", to: "grid#disable_login", as: :grid_disable_login
    post "grid/hackrs/:hackr_id/enable_login", to: "grid#enable_login", as: :grid_enable_login
    post "grid/hackrs/:hackr_id/toggle_service_account", to: "grid#toggle_service_account", as: :grid_toggle_service_account
    post "grid/grant_feature", to: "grid#grant_feature", as: :grid_grant_feature
    delete "grid/revoke_feature", to: "grid#revoke_feature", as: :grid_revoke_feature

    # Grid economy (read-only admin dashboard)
    get "grid_economy", to: "grid_economy#index", as: :grid_economy

    # CRED transaction log (read-only, filterable)
    resources :grid_transactions, only: [:index]

    # Impound records (read-only index + dev-only force actions)
    resources :grid_impound_records, only: [:index] do
      member do
        post :force_recover
        post :force_forfeit
      end
    end

    # Hackr inspector + dev tools (per-hackr)
    resources :grid_hackrs, only: %i[index show] do
      member do
        get :edit_stats
        patch :update_stats
        get :warp
        post :perform_warp
        get :mining_rig
        post :force_activate_rig
        post :force_deactivate_rig
        post :force_install_component
        post :force_uninstall_component
      end
    end
    # Hackr item management (prod-safe)
    get "grid_hackrs/:hackr_id/items", to: "grid_hackr_items#index", as: :grid_hackr_items
    post "grid_hackrs/:hackr_id/items/grant", to: "grid_hackr_items#grant", as: :grant_grid_hackr_item
    delete "grid_hackrs/:hackr_id/items/:id", to: "grid_hackr_items#remove", as: :remove_grid_hackr_item

    # BREACH sandbox (dev-only)
    resources :grid_breach_sandbox, only: %i[new create show] do
      member do
        post :command
        delete :abort
      end
    end

    # NPC Dialogue Tester (dev-only)
    resource :grid_npc_dialogue_tester, only: %i[new create show], controller: "grid_npc_dialogue_tester" do
      post :command
      delete :finish
    end

    # PAC Escape Tester (dev-only)
    resource :grid_pac_escape_tester, only: %i[new create show], controller: "grid_pac_escape_tester" do
      post :command
      delete :finish
    end

    # Grid achievements (runtime CRUD + manual award)
    resources :grid_achievements do
      member do
        post :award
        get :history
      end
    end

    # Grid factions (full CRUD + rep-link management)
    resources :grid_factions do
      member do
        get :history
      end
      collection do
        post :update_rep_links
      end
    end

    # Grid reputations (read + adjust per-hackr)
    resources :grid_hackr_reputations, only: [:index] do
      collection do
        post :adjust
      end
    end

    # Grid reputation event log (read-only)
    resources :grid_reputation_events, only: [:index]

    # Grid item definitions (item master catalog)
    resources :grid_item_definitions, except: [:show] do
      member do
        get :history
      end
    end

    # Grid shops (runtime CRUD + stock management)
    resources :grid_shop_listings do
      member do
        post :restock
        get :history
      end
    end
    resources :grid_shop_transactions, only: [:index]

    # Grid missions (runtime CRUD)
    resources :grid_mission_arcs do
      member do
        get :history
      end
    end
    resources :grid_missions do
      member do
        get :history
      end
    end
    resources :grid_hackr_missions, only: %i[index show]

    # BREACH templates
    resources :grid_breach_templates, except: [:show] do
      member do
        get :history
      end
    end

    # BREACH encounters (placed in rooms)
    resources :grid_breach_encounters, except: [:show] do
      member do
        get :history
        post :make_available
      end
    end

    # Transit system
    resources :grid_transit_types, except: [:show] do
      member do
        get :history
      end
    end
    resources :grid_transit_routes do
      member do
        get :history
        post :add_stop
        delete :remove_stop
      end
    end
    resources :grid_slipstream_routes do
      member do
        get :history
      end
    end
    resources :grid_transit_journeys, only: %i[index show] do
      member do
        post :force_abandon
      end
    end

    # Grid schematics (fabrication recipes)
    resources :grid_schematics, except: [:show] do
      member do
        get :history
      end
    end

    # Starting rooms (tutorial graduation choices)
    resources :grid_starting_rooms, except: [:show] do
      member do
        get :history
      end
    end

    # Hackr Handbook (docs — full CRUD)
    resources :handbook_sections do
      member do
        get :history
      end
    end
    resources :handbook_articles do
      member do
        get :history
      end
    end

    # PulseWire moderation (still functional - runtime operations)
    resources :pulse_wire, only: %i[index destroy] do
      collection do
        get "signal_drops"
        post "bulk_signal_drop"
        delete "bulk_destroy"
      end
      member do
        post "signal_drop"
        post "restore"
      end
    end

    # Hackr streams (still functional - runtime operations)
    resources :hackr_streams do
      member do
        post :go_live
        post :end_stream
      end
    end

    resources :redirects

    # Uplink admin routes (moderation is still functional)
    resources :uplink, only: [:index] do
      collection do
        get "packets"
        get "punishments"
        get "moderation_log"
      end
    end
    get "uplink/channels/:slug/edit", to: "uplink#edit_channel", as: :edit_uplink_channel
    patch "uplink/channels/:slug", to: "uplink#update_channel", as: :uplink_channel
    delete "uplink/packets/:id", to: "uplink#destroy_packet", as: :destroy_uplink_packet
    post "uplink/packets/:id/drop", to: "uplink#drop_packet", as: :drop_uplink_packet
    post "uplink/packets/:id/restore", to: "uplink#restore_packet", as: :restore_uplink_packet
    post "uplink/users/:id/squelch", to: "uplink#squelch_user", as: :squelch_uplink_user
    post "uplink/users/:id/blackout", to: "uplink#blackout_user", as: :blackout_uplink_user
    delete "uplink/punishments/:id", to: "uplink#lift_punishment", as: :lift_uplink_punishment

    # Overlay admin routes
    # Runtime operations (ticker updates, alerts) are still functional
    get "overlays", to: "overlays#index", as: :overlays
    patch "overlays/ticker/:ticker_slug", to: "overlays#update_ticker", as: :update_overlay_ticker
    post "overlays/alert", to: "overlays#send_alert", as: :send_overlay_alert

    # Read-only overlay resources (managed via data/overlays/*.yml)
    resources :overlay_scenes, path: "overlays/scenes", only: %i[index show]
    resources :overlay_elements, path: "overlays/elements", only: %i[index show]
    resources :overlay_lower_thirds, path: "overlays/lower-thirds", only: %i[index show]
    resources :overlay_scene_groups, path: "overlays/groups", only: %i[index show]
  end

  # OBS Overlay routes (Rails server-rendered, NOT SPA)
  scope :overlays do
    get "now-playing", to: "overlays#now_playing", as: :overlay_now_playing
    get "pulsewire", to: "overlays#pulsewire", as: :overlay_pulsewire
    get "grid-activity", to: "overlays#grid_activity", as: :overlay_grid_activity
    get "alerts", to: "overlays#alerts", as: :overlay_alerts
    get "lower-third/:slug", to: "overlays#lower_third", as: :overlay_lower_third
    get "codex/:slug", to: "overlays#codex", as: :overlay_codex
    get "ticker/:position", to: "overlays#ticker", as: :overlay_ticker
    get "scenes/:slug", to: "overlays#scene", as: :overlay_scene
  end

  # Development-only error page testing routes
  if Rails.env.development?
    get "test/404", to: proc { |_env| [404, {}, [File.read(Rails.public_path.join("404.html"))]] }
    get "test/500", to: proc { |_env| [500, {}, [File.read(Rails.public_path.join("500.html"))]] }
  end

  # Catch-all route for 404s (must be last)
  # Uses a controller action so ApplicationController before_actions (redirects) still fire
  # Exclude Active Storage paths from catch-all
  match "*path", to: "pages#not_found",
    via: :all,
    constraints: ->(req) { !req.path.start_with?("/rails/active_storage", "/cable") }
end
