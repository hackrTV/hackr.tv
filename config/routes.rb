Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Root route (SPA)
  root "pages#spa_root"

  # The.CyberPul.se routes (nested under /thecyberpulse) - SPA
  scope "thecyberpulse" do
    get "/", to: "pages#spa_root", as: :thecyberpulse
    get "trackz", to: "pages#spa_root", as: :thecyberpulse_tracks
    get "trackz/:id", to: "pages#spa_root", as: :thecyberpulse_track
    get "vidz", to: "pages#spa_root", as: :thecyberpulse_vidz
    get "vidz/:id", to: "pages#spa_root", as: :thecyberpulse_vod
  end

  # XERAEN routes - SPA
  scope "xeraen" do
    get "/", to: "pages#spa_root", as: :xeraen
    get "trackz", to: "pages#spa_root", as: :xeraen_tracks
    get "trackz/:id", to: "pages#spa_root", as: :xeraen_track
    get "vidz", to: "pages#spa_root", as: :xeraen_vidz
    get "vidz/:id", to: "pages#spa_root", as: :xeraen_vod
  end

  # Band profile routes - SPA (consolidated dynamic route)
  band_slugs = %w[system_rot wavelength_zero voiceprint temporal_blue_drift
    injection_vector cipher_protocol blitzbeam apex_overdrive ethereality
    neon_hearts offline heartbreak_havoc]
  get ":band_slug", to: "pages#spa_root", as: :band,
    constraints: {band_slug: Regexp.union(band_slugs)}

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
    get "identity", to: "pages#spa_root", as: :grid_identity
    get "reset_password/:token", to: "pages#spa_root", as: :grid_password_reset
    get "confirm_email_change/:token", to: "pages#spa_root", as: :grid_confirm_email_change
  end

  # hackr.fm routes - SPA
  scope "fm" do
    get "/", to: "pages#spa_root", as: :fm
    get "radio", to: "pages#spa_root", as: :fm_radio
    get "pulse_vault", to: "pages#spa_root", as: :fm_pulse_vault
    get "bands", to: "pages#spa_root", as: :fm_bands
    get "playlists", to: "pages#spa_root", as: :fm_playlists
    get "playlists/:id", to: "pages#spa_root", as: :fm_playlist
  end

  # Shared playlist - public (SPA)
  get "shared/:token", to: "pages#spa_root", as: :shared_playlist

  # HackrLogs (blog) routes - SPA
  scope "logs" do
    get "/", to: "pages#spa_root", as: :hackr_logs
    get ":id", to: "pages#spa_root", as: :hackr_log
  end

  # Codex (wiki) routes - SPA
  scope "codex" do
    get "/", to: "pages#spa_root", as: :codex
    get ":slug", to: "pages#spa_root", as: :codex_entry
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
    end
    resources :tracks, only: %i[index show]
    resources :albums, only: %i[index show]
    get "codex/mappings", to: "codex#mappings"
    get "codex", to: "codex#index"
    get "codex/:slug", to: "codex#show"
    get "radio_stations", to: "radio#index"
    get "radio_stations/:id/playlists", to: "radio#station_playlists"
    get "hackr_stream", to: "hackr_streams#show"
    get "artists/:artist_slug/vods", to: "hackr_streams#index"
    get "artists/:artist_slug/vods/:id", to: "hackr_streams#vod_show"

    # Grid API routes
    get "grid/current_hackr", to: "grid#current_hackr_info"
    post "grid/login", to: "grid#login"
    post "grid/register", to: "grid#register"
    get "grid/verify/:token", to: "grid#verify_token"
    post "grid/complete_registration", to: "grid#complete_registration"
    delete "grid/disconnect", to: "grid#disconnect"
    post "grid/command", to: "grid#command"
    post "grid/request_password_reset", to: "grid#request_password_reset"
    post "grid/reset_password", to: "grid#reset_password"
    post "grid/request_email_change", to: "grid#request_email_change"
    post "grid/confirm_email_change", to: "grid#confirm_email_change"

    # Hackr Logs API routes
    resources :logs, only: %i[index show]

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
    end
  end

  # Admin routes (accessible at /root)
  # NOTE: Most resources are read-only (managed via YAML files)
  # Edit YAML files in data/ directory and run: rails data:load
  namespace :admin, path: "root" do
    root "dashboard#index"

    # Read-only catalog resources (managed via data/catalog/*.yml)
    resources :artists, only: [:index]
    resources :albums, only: [:index]
    resources :tracks, only: [:index]

    # Read-only content resources (managed via data/content/*.yml)
    resources :codex_entries, only: [:index]
    resources :hackr_logs, only: [:index]

    # Read-only system resources (managed via data/system/*.yml)
    resources :radio_stations, only: %i[index show]
    resources :zone_playlists, only: %i[index show]

    # Read-only world resources (managed via data/world/*.yml)
    resources :grid_zones, only: [:index]
    resources :grid_rooms, only: [:index]

    # Grid management (still functional - runtime operations)
    get "grid", to: "grid#index", as: :grid
    post "grid/broadcast", to: "grid#broadcast", as: :grid_broadcast
    post "grid/grant_feature", to: "grid#grant_feature", as: :grid_grant_feature
    delete "grid/revoke_feature", to: "grid#revoke_feature", as: :grid_revoke_feature

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

    # Redirects are read-only (managed via data/system/redirects.yml)
    resources :redirects, only: [:index]

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
    constraints: ->(req) { !req.path.start_with?("/rails/active_storage") }
end
