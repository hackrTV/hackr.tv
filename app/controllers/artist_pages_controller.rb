# Bespoke artist pages (Hotwire, Phase 4) — replaces the six standalone
# React pages under components/pages/artist/: TheCyberPulseLandingPage,
# TheCyberPulsePage (bio), XeraenLandingPage, XeraenPage (bio),
# SectorXPage, and WavelengthZeroPage.
class ArtistPagesController < ApplicationController
  include GridAuthentication

  layout "hotwire"

  # Port of TheCyberPulsePage extractVideoId — same URL shapes, same
  # 11-character video ids.
  YOUTUBE_ID_PATTERNS = [
    %r{youtube\.com/embed/([a-zA-Z0-9_-]{11})},
    %r{youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})},
    %r{youtu\.be/([a-zA-Z0-9_-]{11})},
    %r{youtube\.com/live/([a-zA-Z0-9_-]{11})}
  ].freeze

  def thecyberpulse_landing
  end

  def thecyberpulse_bio
    # Mirrors the SPA's /api/artists/thecyberpulse/vods fetch
    # (Api::HackrStreamsController#index): the newest VOD feeds the
    # VISUAL TRANSMISSION embed. Like the React page, the section is
    # omitted when there is no VOD or no extractable video id.
    artist = Artist.find_by(slug: "thecyberpulse")
    return if artist.nil?

    @latest_vod = artist.hackr_streams
      .where.not(vod_url: [nil, ""])
      .order(started_at: :desc, created_at: :desc)
      .first
    @vod_video_id = @latest_vod && youtube_video_id(@latest_vod.vod_url)
  end

  def xeraen_landing
  end

  def xeraen_bio
    # Mirrors the SPA's /api/artists/xeraen fetch (Api::ArtistsController#show)
    # plus the client-side featured filter + release_date sort: the newest
    # featured pulse-vault track feeds the LATEST TRANSMISSION player.
    artist = Artist.find_by(slug: "xeraen")
    return if artist.nil?

    @latest_featured_track = artist.tracks.visible_in_pulse_vault
      .where(featured: true)
      .includes(:artist, release: {cover_image_attachment: :blob})
      .order(Arel.sql("releases.release_date DESC NULLS LAST, tracks.track_number ASC"))
      .first
  end

  def sector_x
  end

  def wavelength_zero
  end

  private

  def youtube_video_id(url)
    YOUTUBE_ID_PATTERNS.each do |pattern|
      match = pattern.match(url.to_s)
      return match[1] if match
    end
    nil
  end
end
