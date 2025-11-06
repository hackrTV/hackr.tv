Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", :as => :rails_health_check

  # Root route
  root "pages#index"

  # XERAEN routes
  get "xeraen", to: "pages#xeraen"
  get "xeraen/linkz", to: "pages#xeraen_linkz", as: :xeraen_linkz
  get "xeraen/trackz", to: "tracks#index", as: :xeraen_tracks
  get "xeraen/trackz/:id", to: "tracks#show", as: :xeraen_track

  # Sector X routes
  get "sector/x", to: "pages#sector_x", as: :sector_x

  # The Cyber Pulse tracks (default artist)
  get "trackz", to: "tracks#index", as: :tracks
  get "trackz/:id", to: "tracks#show", as: :track

  # THE PULSE GRID routes
  get "grid", to: "grid#index", as: :grid
  get "grid/login", to: "grid#login", as: :grid_login
  post "grid/login", to: "grid#create_session"
  get "grid/register", to: "grid#register", as: :grid_register
  post "grid/register", to: "grid#create_hackr"
  delete "grid/logout", to: "grid#logout", as: :grid_logout
  post "grid/command", to: "grid#command", as: :grid_command

  # Development-only error page testing routes
  if Rails.env.development?
    get "test/404", to: proc { |env| [404, {}, [File.read(Rails.public_path.join("404.html"))]] }
    get "test/500", to: proc { |env| [500, {}, [File.read(Rails.public_path.join("500.html"))]] }
  end

  # Catch-all route for 404s (must be last)
  match "*path", to: proc { |env| [404, {}, [File.read(Rails.public_path.join("404.html"))]] }, via: :all
end
