# Band profile pages (Hotwire, Phase 4) — replaces BandProfilePage.tsx +
# BandProfileLayout.tsx for the bands configured in BandProfile::CONFIG.
# The slug arrives via route defaults from each artist scope. Unknown
# slugs render a minimal "Band not found" page with a 200, matching the
# SPA behavior.
class BandProfilesController < ApplicationController
  include GridAuthentication

  def show
    @slug = params[:artist_slug].to_s
    @profile = BandProfile::CONFIG[@slug]
    @artist = Artist.find_by(slug: @slug) if @profile
  end
end
