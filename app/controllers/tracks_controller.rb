class TracksController < ApplicationController
  before_action :set_artist, except: [:legacy_redirect, :legacy_redirect_show]

  def index
    @tracks = @artist.tracks.includes(:album).ordered
  end

  def show
    @track = @artist.tracks.includes(:album).find_by!(slug: params[:id])
  end

  # Legacy redirect for /trackz -> /thecyberpulse/trackz
  def legacy_redirect
    redirect_to thecyberpulse_tracks_path, status: 301
  end

  # Legacy redirect for /trackz/:id -> /thecyberpulse/trackz/:id
  def legacy_redirect_show
    redirect_to thecyberpulse_track_path(params[:id]), status: 301
  end

  private

  def set_artist
    artist_slug = params[:artist_id] || infer_artist_from_path
    @artist = Artist.find_by!(slug: artist_slug)
  end

  def infer_artist_from_path
    # Infer artist from path: /xeraen/trackz -> xeraen, /thecyberpulse/trackz -> thecyberpulse
    if request.path.include?("/xeraen/")
      "xeraen"
    elsif request.path.include?("/thecyberpulse/")
      "thecyberpulse"
    else
      "thecyberpulse" # Default fallback
    end
  end
end
