# Fracture Network roster at /f/net (Hotwire, Phase 4) — replaces
# BandsPage.tsx.
class BandsController < ApplicationController
  include GridAuthentication

  layout "hotwire"

  def index
    # Mirrors Api::ArtistsController#index (no type param => bands) plus
    # the case-insensitive name sort the React page applied client-side.
    @artists = Artist.bands.order(:name).sort_by { |artist| artist.name.to_s.downcase }
  end
end
