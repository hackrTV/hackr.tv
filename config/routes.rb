Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

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
end
