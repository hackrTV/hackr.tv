class PagesController < ApplicationController
  def index
    render "mobile/index" if mobile?
  end

  def xeraen
    render "mobile/xeraen" if mobile?
  end

  def xeraen_linkz
  end

  def system_rot
    @artist = Artist.find_by(slug: "system_rot")
    @tracks = @artist.tracks.includes(:album).album_order if @artist
  end

  def wavelength_zero
    @artist = Artist.find_by(slug: "wavelength_zero")
    @tracks = @artist.tracks.includes(:album).album_order if @artist
  end

  def voiceprint
    @artist = Artist.find_by(slug: "voiceprint")
    @tracks = @artist.tracks.includes(:album).album_order if @artist
  end

  def temporal_blue_drift
    @artist = Artist.find_by(slug: "temporal_blue_drift")
    @tracks = @artist.tracks.includes(:album).album_order if @artist
  end

  def sector_x
  end
end
