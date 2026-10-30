# Artist catalog (Hotwire, Phase 4) — replaces ReleaseListPage.tsx,
# ReleaseDetailPage.tsx, TrackDetailPage.tsx, VodzPage.tsx and
# VodzShowPage.tsx. All artist slugs share these actions; the slug arrives
# as params[:artist_slug] from the route scope.
class ArtistCatalogController < ApplicationController
  include GridAuthentication

  # The catalog console (2026-10-29): /releases, /releases/:id and
  # /trackz/:id as left-anchored terminal screens on the home console
  # family (console_releases / console_release / console_track, artist_catalog.css
  # "Catalog console"). XERAEN first, The.CyberPul.se the same day — the
  # other slugs keep the card grid + fieldset stack until XERAEN settles
  # the design (or drops it); widening is one slug here, a destination
  # row set in ArtistConsoleHelper and a .console--<slug> brand block in
  # artist_pages.css.
  CONSOLE_CATALOG_SLUGS = %w[xeraen thecyberpulse].freeze

  # GET /:artist_slug/releases
  def releases
    @artist = Artist.find_by(slug: params[:artist_slug])

    # Mirrors Api::ReleasesController#index + #coming_soon, folded down to
    # the one artist the React page filtered to client-side. Same
    # visibility rule: a release whose tracks are all hidden from the
    # Pulse Vault stays hidden here too.
    @releases = Release.includes(:artist, :tracks, cover_image_attachment: :blob).catalog_visible(@artist)

    @coming_soon = Release.includes(:artist, :tracks, cover_image_attachment: :blob)
      .where(artist: @artist, coming_soon: true)
      .order(Arel.sql("release_date ASC NULLS LAST"))
      .to_a

    # React only swapped the slug for the artist name once a release row
    # resolved; an artist with zero releases keeps the upcased slug.
    @artist_name = (@releases.first || @coming_soon.first)&.artist&.name ||
      params[:artist_slug].upcase

    # View credit inline — feeds the release_indexes_viewed_all
    # achievement.
    if current_hackr && @artist
      HackrPageView.record!(current_hackr, "release_index", @artist.id)
      Grid::AchievementChecker.new(current_hackr).check("release_indexes_viewed_all")
    end

    render :console_releases if console_catalog?
  end

  # GET /:artist_slug/releases/:id
  def release
    # Slug-or-id lookup mirroring Api::ReleasesController#show (the slug
    # namespace is global there too — the artist segment is cosmetic).
    @release = Release.includes(:artist).find_by(slug: params[:id])
    @release ||= Release.includes(:artist).find_by(id: params[:id]) if numeric_id?

    # Hidden-from-vault releases 404 like the API; React rendered its
    # SIGNAL LOST state for both that and unknown ids.
    @release = nil if @release && hidden_from_vault?(@release)

    if @release.nil?
      render (console_catalog? ? :console_release : :release), status: :not_found
      return
    end

    # View credit inline (the SPA fired POST /api/releases/:slug/viewed);
    # coming-soon releases are excluded, matching the API. Before the
    # single redirect, so a single still counts toward releases_viewed_all.
    if current_hackr && !@release.coming_soon
      HackrPageView.record!(current_hackr, "release", @release.id)
      Grid::AchievementChecker.new(current_hackr).check("releases_viewed_all")
    end

    # A single on the console is its track's page (Release#single?): the
    # ledger links there directly; this catches the release URL arriving
    # from elsewhere (the FM cards, the API's redirect signal, bookmarks).
    if console_catalog? && @release.single?
      redirect_to "/#{params[:artist_slug]}/trackz/#{@release.tracks.first.slug}"
      return
    end

    @tracks = @release.tracks.includes(:hackr_streams, release: {cover_image_attachment: :blob})
      .with_attached_audio_file
      .order(:track_number, :title)
    @disc_length = helpers.format_seconds(@tracks.sum { |t| helpers.duration_seconds(t.duration) })

    render :console_release if console_catalog?
  end

  # GET /:artist_slug/trackz/:id
  def track
    @track = Track.includes(:artist, :hackr_streams, release: {cover_image_attachment: :blob})
      .find_by(slug: params[:id])
    if @track.nil? && numeric_id?
      @track = Track.includes(:artist, :hackr_streams, release: {cover_image_attachment: :blob})
        .find_by(id: params[:id])
    end

    if @track.nil?
      render (console_catalog? ? :console_track : :track), status: :not_found
      return
    end

    # Coming-soon tracks: the API answered 403 + a redirect signal and the
    # React page navigated (replace) to the release page. Redirect here.
    if @track.release&.coming_soon
      redirect_to "/#{@track.artist.slug}/releases/#{@track.release.slug}"
      return
    end

    return unless console_catalog?

    # A single's track page stands in for its release page (the ledger
    # links straight here), so the release view credit lands here too.
    if current_hackr && @track.release&.single?
      HackrPageView.record!(current_hackr, "release", @track.release.id)
      Grid::AchievementChecker.new(current_hackr).check("releases_viewed_all")
    end

    # The console screen (console_track) reads the release tracklist in
    # disc order for its "NN of N" readout and the // ALSO ON <RELEASE> //
    # rows the prompt numbers open.
    @release_tracks = @track.release.tracks.order(:track_number, :title).to_a
    render :console_track
  end

  # GET /thecyberpulse/vidz — the VIDZ archive: TCP's recordings and
  # XERAEN's (HackrStream.vidz_archive; /xeraen/vidz* redirects here in
  # routes). Before 2026-10-29 the list was @artist's own streams, so an
  # XERAEN VOD was listed nowhere and its page 404'd after the redirect.
  def vidz
    @artist = Artist.find_by(slug: params[:artist_slug])

    if @artist.nil?
      render status: :not_found
      return
    end

    @vods = HackrStream.vidz_archive.includes(:artist)
      .order(started_at: :desc, created_at: :desc)
      .to_a
  end

  # GET /thecyberpulse/vidz/:id (and /xeraen/vidz/:id via the redirect)
  def vidz_show
    @artist = Artist.find_by(slug: params[:artist_slug])
    # The whole archive, newest first: the recording itself plus the
    # console's // ALSO IN THE ARCHIVE // rows, numbered as the index
    # numbers them.
    @archive = @artist ? HackrStream.vidz_archive.includes(:artist).order(started_at: :desc, created_at: :desc).to_a : []
    @vod = @archive.find { |stream| stream.id == params[:id].to_i }

    render status: :not_found if @vod.nil?
  end

  private

  def numeric_id?
    params[:id].to_i.to_s == params[:id]
  end

  def console_catalog?
    CONSOLE_CATALOG_SLUGS.include?(params[:artist_slug])
  end

  def hidden_from_vault?(release)
    !release.coming_soon && release.tracks.any? &&
      release.tracks.where(show_in_pulse_vault: true).none?
  end
end
