# Artist catalog (Hotwire, Phase 4) — replaces ReleaseListPage.tsx,
# ReleaseDetailPage.tsx, TrackDetailPage.tsx, VodzPage.tsx and
# VodzShowPage.tsx. All artist slugs share these actions; the slug arrives
# as params[:artist_slug] from the route scope.
class ArtistCatalogController < ApplicationController
  include GridAuthentication

  layout "hotwire"

  # GET /:artist_slug/releases
  def releases
    @artist = Artist.find_by(slug: params[:artist_slug])

    # Mirrors Api::ReleasesController#index + #coming_soon, folded down to
    # the one artist the React page filtered to client-side. Same
    # visibility rule: a release whose tracks are all hidden from the
    # Pulse Vault stays hidden here too.
    @releases = Release.includes(:artist, cover_image_attachment: :blob)
      .where(artist: @artist, coming_soon: false)
      .order(Arel.sql("release_date DESC NULLS LAST"))
      .reject { |r| r.tracks.any? && r.tracks.where(show_in_pulse_vault: true).none? }

    @coming_soon = Release.includes(:artist, cover_image_attachment: :blob)
      .where(artist: @artist, coming_soon: true)
      .order(Arel.sql("release_date ASC NULLS LAST"))
      .to_a

    # React only swapped the slug for the artist name once a release row
    # resolved; an artist with zero releases keeps the upcased slug.
    @artist_name = (@releases.first || @coming_soon.first)&.artist&.name ||
      params[:artist_slug].upcase

    # View credit inline (the SPA fired
    # POST /api/artists/:slug/release_index_viewed on mount).
    if current_hackr && @artist
      HackrPageView.record!(current_hackr, "release_index", @artist.id)
      Grid::AchievementChecker.new(current_hackr).check("release_indexes_viewed_all")
    end
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
      render status: :not_found
      return
    end

    @tracks = @release.tracks.includes(:hackr_streams, release: {cover_image_attachment: :blob})
      .with_attached_audio_file
      .order(:track_number, :title)
    @disc_length = format_duration(@tracks.sum { |t| parse_duration(t.duration) })

    # View credit inline (the SPA fired POST /api/releases/:slug/viewed);
    # coming-soon releases are excluded, matching the API.
    if current_hackr && !@release.coming_soon
      HackrPageView.record!(current_hackr, "release", @release.id)
      Grid::AchievementChecker.new(current_hackr).check("releases_viewed_all")
    end
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
      render status: :not_found
      return
    end

    # Coming-soon tracks: the API answered 403 + a redirect signal and the
    # React page navigated (replace) to the release page. Redirect here.
    if @track.release&.coming_soon
      redirect_to "/#{@track.artist.slug}/releases/#{@track.release.slug}"
    end
  end

  # GET /thecyberpulse/vidz and /xeraen/vidz
  def vidz
    @artist = Artist.find_by(slug: params[:artist_slug])

    if @artist.nil?
      render status: :not_found
      return
    end

    # Mirrors Api::HackrStreamsController#index.
    @vods = @artist.hackr_streams
      .where.not(vod_url: [nil, ""])
      .order(started_at: :desc, created_at: :desc)
      .to_a

    # VodzPage bounced an empty XERAEN vidz list over to thecyberpulse.
    if @vods.empty? && @artist.slug == "xeraen"
      redirect_to "/thecyberpulse/vidz"
    end
  end

  # GET /thecyberpulse/vidz/:id and /xeraen/vidz/:id
  def vidz_show
    @artist = Artist.find_by(slug: params[:artist_slug])
    @vod = @artist&.hackr_streams&.find_by(id: params[:id])

    render status: :not_found if @vod.nil?
  end

  private

  def numeric_id?
    params[:id].to_i.to_s == params[:id]
  end

  def hidden_from_vault?(release)
    !release.coming_soon && release.tracks.any? &&
      release.tracks.where(show_in_pulse_vault: true).none?
  end

  # Ported from Api::ReleasesController — disc length is the summed track
  # durations, rendered M:SS.
  def parse_duration(duration_str)
    return 0 if duration_str.blank?
    parts = duration_str.split(":").map(&:to_i)
    if parts.length == 2
      parts[0] * 60 + parts[1]
    elsif parts.length == 3
      parts[0] * 3600 + parts[1] * 60 + parts[2]
    else
      0
    end
  end

  def format_duration(total_seconds)
    minutes = total_seconds / 60
    seconds = total_seconds % 60
    "#{minutes}:#{seconds.to_s.rjust(2, "0")}"
  end
end
