# Band profile pages (Hotwire, Phase 4) — replaces BandProfilePage.tsx +
# BandProfileLayout.tsx for the bands configured in BandProfile::CONFIG.
# The slug arrives via route defaults from each artist scope, or from the
# dynamic :artist_slug scope for any other DB artist. Slugs without a
# profile render the Coming Soon console screen with a 200.
class BandProfilesController < ApplicationController
  include GridAuthentication

  def show
    @slug = params[:artist_slug].to_s
    @profile = BandProfile::CONFIG[@slug]
    @artist = Artist.find_by(slug: @slug)
  end
end
