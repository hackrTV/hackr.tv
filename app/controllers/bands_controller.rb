# Fracture Network roster at /f/net (Hotwire, Phase 4) — replaces
# BandsPage.tsx.
class BandsController < ApplicationController
  include GridAuthentication

  def index
    @artists = Artist.bands.ordered.to_a
    @releases_by_artist = Release.released.where(artist_id: @artists.map(&:id))
      .includes(:tracks, cover_image_attachment: :blob)
      .order(Arel.sql("release_date DESC NULLS LAST"))
      .reject(&:vault_hidden?)
      .group_by(&:artist_id)
  end
end
