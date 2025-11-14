Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Root route - hackr.tv home
  root "pages#hackr_tv"

  # The.CyberPul.se routes (nested under /thecyberpulse)
  get "thecyberpulse", to: "pages#thecyberpulse", as: :thecyberpulse
  get "thecyberpulse/trackz", to: "tracks#index", as: :thecyberpulse_tracks
  get "thecyberpulse/trackz/:id", to: "tracks#show", as: :thecyberpulse_track

  # XERAEN routes
  get "xeraen", to: "pages#xeraen"
  get "xeraen/linkz", to: "pages#xeraen_linkz", as: :xeraen_linkz
  get "xeraen/trackz", to: "tracks#index", as: :xeraen_tracks
  get "xeraen/trackz/:id", to: "tracks#show", as: :xeraen_track

  # System Rot routes
  get "system_rot", to: "pages#system_rot", as: :system_rot

  # Wavelength Zero routes
  get "wavelength_zero", to: "pages#wavelength_zero", as: :wavelength_zero

  # Voiceprint routes
  get "voiceprint", to: "pages#voiceprint", as: :voiceprint

  # Temporal Blue Drift routes
  get "temporal_blue_drift", to: "pages#temporal_blue_drift", as: :temporal_blue_drift

  # Sector X routes
  get "sector/x", to: "pages#sector_x", as: :sector_x

  # Legacy routes for backward compatibility (redirects to new paths)
  get "trackz", to: "tracks#legacy_redirect", as: :legacy_tracks
  get "trackz/:id", to: "tracks#legacy_redirect_show", as: :legacy_track

  # THE PULSE GRID routes
  get "grid", to: "grid#index", as: :grid
  get "grid/login", to: "grid#login", as: :grid_login
  post "grid/login", to: "grid#create_session"
  get "grid/register", to: "grid#register", as: :grid_register
  post "grid/register", to: "grid#create_hackr"
  delete "grid/disconnect", to: "grid#disconnect", as: :grid_disconnect
  post "grid/command", to: "grid#command", as: :grid_command

  # hackr.fm routes
  get "fm", to: "fm#index", as: :fm
  get "fm/radio", to: "fm#radio", as: :fm_radio
  get "fm/pulse_vault", to: "fm#pulse_vault", as: :fm_pulse_vault
  get "fm/bands", to: "fm#bands", as: :fm_bands

  # HackrLogs (blog) routes
  get "logs", to: "hackr_logs#index", as: :hackr_logs
  get "logs/:id", to: "hackr_logs#show", as: :hackr_log

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
