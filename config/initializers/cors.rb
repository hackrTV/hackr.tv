# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  # The external HUD app (OBS browser sources) reads the overlay data
  # surface + world event feed cross-origin.
  allow do
    origins "*"
    resource "/api/overlay/*", headers: :any, methods: [:get]
    resource "/api/world_events", headers: :any, methods: [:get]
  end
end
