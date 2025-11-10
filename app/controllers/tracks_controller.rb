class TracksController < ApplicationController
  before_action :set_artist

  def index
    @tracks = @artist.tracks.includes(:album).ordered
  end

  def show
    @track = @artist.tracks.includes(:album).find_by!(slug: params[:id])
  end

  private

  def set_artist
    artist_slug = params[:artist_id] || infer_artist_from_path
    @artist = Artist.find_by!(slug: artist_slug)
  end

  def infer_artist_from_path
    # Infer artist from path: /xeraen/trackz -> xeraen, /trackz -> thecyberpulse
    if request.path.include?("/xeraen/")
      "xeraen"
    else
      "thecyberpulse"
    end
  end
end
