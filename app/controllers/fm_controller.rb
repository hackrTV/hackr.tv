# hackr.fm landing + releases (Hotwire, Phase 4) — replaces
# FmLandingPage.tsx and FmReleasesPage.tsx.
class FmController < ApplicationController
  include GridAuthentication

  def show
    @catalog = label_catalog
    @latest_releases = @catalog.select { |r| r.cover_image.attached? }.first(3)

    @coming_soon = Release.includes(:artist, :tracks, cover_image_attachment: :blob)
      .where(coming_soon: true)
      .order(Arel.sql("release_date ASC NULLS LAST"))
      .to_a

    @artist_count = Artist.bands.count
  end

  def releases
    @releases = label_catalog
  end

  private

  def label_catalog
    Release.includes(:artist, :tracks, cover_image_attachment: :blob)
      .where(label: "hackr.fm", coming_soon: false)
      .order(Arel.sql("release_date DESC NULLS LAST"))
      .reject(&:vault_hidden?)
  end
end
