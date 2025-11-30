Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Root route (SPA)
  root "pages#spa_root"

  # The.CyberPul.se routes (nested under /thecyberpulse) - SPA
  get "thecyberpulse", to: "pages#spa_root", as: :thecyberpulse
  get "thecyberpulse/trackz", to: "pages#spa_root", as: :thecyberpulse_tracks
  get "thecyberpulse/trackz/:id", to: "pages#spa_root", as: :thecyberpulse_track

  # XERAEN routes - SPA
  get "xeraen", to: "pages#spa_root"
  get "xeraen/linkz", to: "pages#spa_root", as: :xeraen_linkz
  get "xeraen/trackz", to: "pages#spa_root", as: :xeraen_tracks
  get "xeraen/trackz/:id", to: "pages#spa_root", as: :xeraen_track

  # Band profile routes - SPA
  get "system_rot", to: "pages#spa_root", as: :system_rot
  get "wavelength_zero", to: "pages#spa_root", as: :wavelength_zero
  get "voiceprint", to: "pages#spa_root", as: :voiceprint
  get "temporal_blue_drift", to: "pages#spa_root", as: :temporal_blue_drift
  get "injection_vector", to: "pages#spa_root", as: :injection_vector
  get "cipher_protocol", to: "pages#spa_root", as: :cipher_protocol
  get "blitzbeam", to: "pages#spa_root", as: :blitzbeam
  get "apex_overdrive", to: "pages#spa_root", as: :apex_overdrive
  get "ethereality", to: "pages#spa_root", as: :ethereality
  get "neon_hearts", to: "pages#spa_root", as: :neon_hearts
  get "offline", to: "pages#spa_root", as: :offline

  # Sector X routes - SPA
  get "sector/x", to: "pages#spa_root", as: :sector_x

  # Legacy routes for backward compatibility (redirects to new paths)
  get "trackz", to: "tracks#legacy_redirect", as: :legacy_tracks
  get "trackz/:id", to: "tracks#legacy_redirect_show", as: :legacy_track

  # THE PULSE GRID routes (SPA)
  get "grid", to: "pages#spa_root", as: :grid
  get "grid/login", to: "pages#spa_root", as: :grid_login
  get "grid/register", to: "pages#spa_root", as: :grid_register

  # hackr.fm routes - SPA
  get "fm", to: "pages#spa_root", as: :fm
  get "fm/radio", to: "pages#spa_root", as: :fm_radio
  get "fm/pulse_vault", to: "pages#spa_root", as: :fm_pulse_vault
  get "fm/bands", to: "pages#spa_root", as: :fm_bands
  get "fm/playlists", to: "pages#spa_root", as: :fm_playlists
  get "fm/playlists/:id", to: "pages#spa_root", as: :fm_playlist

  # Shared playlist - public (SPA)
  get "shared/:token", to: "pages#spa_root", as: :shared_playlist

  # HackrLogs (blog) routes - SPA
  get "logs", to: "pages#spa_root", as: :hackr_logs
  get "logs/:id", to: "pages#spa_root", as: :hackr_log

  # Codex (wiki) routes - SPA
  get "codex", to: "pages#spa_root", as: :codex
  get "codex/:slug", to: "pages#spa_root", as: :codex_entry

  # PulseWire routes - SPA
  get "wire", to: "pages#spa_root", as: :wire
  get "wire/:username", to: "pages#spa_root", as: :wire_user
  get "wire/pulse/:id", to: "pages#spa_root", as: :wire_pulse

  # API routes (for SPA)
  namespace :api, defaults: {format: :json} do
    resources :artists, only: [:index, :show] do
      resources :tracks, only: [:index]
    end
    resources :tracks, only: [:index, :show]
    resources :albums, only: [:index, :show]
    get "codex/mappings", to: "codex#mappings"
    get "codex", to: "codex#index"
    get "codex/:slug", to: "codex#show"
    get "radio_stations", to: "radio#index"
    get "radio_stations/:id/playlists", to: "radio#station_playlists"
    get "hackr_stream", to: "hackr_streams#show"

    # Grid API routes
    get "grid/current_hackr", to: "grid#current_hackr_info"
    post "grid/login", to: "grid#login"
    post "grid/register", to: "grid#register"
    delete "grid/disconnect", to: "grid#disconnect"
    post "grid/command", to: "grid#command"

    # Hackr Logs API routes
    resources :logs, only: [:index, :show]

    # Playlists API routes
    resources :playlists do
      post "reorder", on: :member
      resources :tracks, controller: "playlist_tracks", only: [:create, :destroy]
    end
    get "shared_playlists/:share_token", to: "shared_playlists#show"

    # PulseWire API routes
    resources :pulses, only: [:index, :show, :create, :destroy] do
      post "signal_drop", on: :member
      post "echo", to: "echoes#create"
      get "echoes", to: "echoes#index"
    end

    # Overlay API routes
    post "overlay/now-playing", to: "overlay#set_now_playing"
  end

  # Admin routes (accessible at /root)
  namespace :admin, path: "root" do
    root "dashboard#index"
    resources :artists
    resources :albums
    resources :tracks do
      collection do
        post :import
      end
    end
    resources :codex_entries
    resources :hackr_logs
    resources :radio_stations do
      member do
        post :add_playlist
        delete :remove_playlist
        post :reorder_playlists
      end
    end
    resources :zone_playlists do
      member do
        post :add_track
        delete "remove_track/:track_id", action: :remove_track, as: :remove_track
        patch :reorder_tracks
      end
    end
    resources :grid_zones, only: [:index, :edit, :update]
    resources :grid_rooms, only: [:index, :edit, :update]
    get "grid", to: "grid#index", as: :grid
    post "grid/broadcast", to: "grid#broadcast", as: :grid_broadcast
    resources :pulse_wire, only: [:index, :destroy] do
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
    resources :hackr_streams do
      member do
        post :go_live
        post :end_stream
      end
    end

    # Overlay admin routes
    get "overlays", to: "overlays#index", as: :overlays
    patch "overlays/ticker/:ticker_slug", to: "overlays#update_ticker", as: :update_overlay_ticker
    post "overlays/alert", to: "overlays#send_alert", as: :send_overlay_alert
    resources :overlay_scenes, path: "overlays/scenes" do
      resources :scene_elements, controller: "overlay_scene_elements", only: [:new, :create, :edit, :update, :destroy]
    end
    resources :overlay_elements, path: "overlays/elements"
    resources :overlay_lower_thirds, path: "overlays/lower-thirds"
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
    get "test/404", to: proc { |env| [404, {}, [File.read(Rails.public_path.join("404.html"))]] }
    get "test/500", to: proc { |env| [500, {}, [File.read(Rails.public_path.join("500.html"))]] }
  end

  # Catch-all route for 404s (must be last)
  # Exclude Active Storage paths from catch-all
  match "*path", to: proc { |env| [404, {}, [File.read(Rails.public_path.join("404.html"))]] },
    via: :all,
    constraints: lambda { |req| !req.path.start_with?("/rails/active_storage") }
end
