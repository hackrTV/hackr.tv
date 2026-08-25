# hackr.fm landing + releases (Hotwire, Phase 4) — replaces
# FmLandingPage.tsx and FmReleasesPage.tsx.
class FmController < ApplicationController
  include GridAuthentication

  layout "hotwire"

  def show
    # Mirrors Api::ReleasesController#latest and #coming_soon (the two
    # fetches the React landing page made on mount).
    @latest_releases = Release.includes(:artist, cover_image_attachment: :blob)
      .where(label: "hackr.fm", coming_soon: false)
      .where.associated(:cover_image_attachment)
      .order(Arel.sql("release_date DESC NULLS LAST"))
      .reject { |r| r.tracks.any? && r.tracks.where(show_in_pulse_vault: true).none? }
      .first(3)

    @coming_soon = Release.includes(:artist, cover_image_attachment: :blob)
      .where(coming_soon: true)
      .order(Arel.sql("release_date ASC NULLS LAST"))
  end

  def releases
    # Mirrors Api::ReleasesController#index; the label filter and the
    # release_date DESC sort the React page applied client-side are folded
    # into the query (same semantics: exact label match, NULLS LAST).
    @releases = Release.includes(:artist, cover_image_attachment: :blob)
      .where(label: "hackr.fm", coming_soon: false)
      .order(Arel.sql("release_date DESC NULLS LAST"))
      .reject { |r| r.tracks.any? && r.tracks.where(show_in_pulse_vault: true).none? }
  end
end
