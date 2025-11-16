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

  # System Rot routes - SPA
  get "system_rot", to: "pages#spa_root", as: :system_rot

  # Wavelength Zero routes - SPA
  get "wavelength_zero", to: "pages#spa_root", as: :wavelength_zero

  # Voiceprint routes - SPA
  get "voiceprint", to: "pages#spa_root", as: :voiceprint

  # Temporal Blue Drift routes - SPA
  get "temporal_blue_drift", to: "pages#spa_root", as: :temporal_blue_drift

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

  # HackrLogs (blog) routes - SPA
  get "logs", to: "pages#spa_root", as: :hackr_logs
  get "logs/:id", to: "pages#spa_root", as: :hackr_log

  # API routes (for SPA)
  namespace :api, defaults: {format: :json} do
    resources :artists, only: [:index, :show] do
      resources :tracks, only: [:index]
    end
    resources :tracks, only: [:index, :show]
    resources :albums, only: [:index, :show]
    get "radio_stations", to: "radio#index"

    # Grid API routes
    get "grid/current_hackr", to: "grid#current_hackr_info"
    post "grid/login", to: "grid#login"
    post "grid/register", to: "grid#register"
    delete "grid/disconnect", to: "grid#disconnect"
    post "grid/command", to: "grid#command"

    # Hackr Logs API routes
    resources :logs, only: [:index, :show]
  end

  # Admin routes (accessible at /root)
  namespace :admin, path: "root" do
    root "dashboard#index"
    resources :artists
    resources :tracks do
      collection do
        post :import
      end
    end
    resources :hackr_logs
    get "grid", to: "grid#index", as: :grid
    post "grid/broadcast", to: "grid#broadcast", as: :grid_broadcast
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
