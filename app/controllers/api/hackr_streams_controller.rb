class Api::HackrStreamsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  # GET /api/hackr_stream - Get current live stream (if any)
  def show
    @stream = HackrStream.includes(:artist).current_live

    if @stream
      render json: {
        is_live: true,
        artist: {
          id: @stream.artist.id,
          name: @stream.artist.name,
          slug: @stream.artist.slug
        },
        title: @stream.title,
        live_url: @stream.live_url,
        vod_url: @stream.vod_url,
        started_at: @stream.started_at
      }
    else
      render json: {
        is_live: false
      }
    end
  end

  # GET /api/artists/:artist_slug/vods - Get all VODs for an artist
  def index
    @artist = Artist.find_by!(slug: params[:artist_slug])
    @streams = @artist.hackr_streams
      .where.not(vod_url: [nil, ""])
      .order(started_at: :desc, created_at: :desc)

    render json: {
      artist: {
        id: @artist.id,
        name: @artist.name,
        slug: @artist.slug
      },
      vods: @streams.map { |stream|
        {
          id: stream.id,
          title: stream.title,
          vod_url: stream.vod_url,
          live_url: stream.live_url,
          started_at: stream.started_at,
          ended_at: stream.ended_at,
          was_livestream: stream.live_url.present?
        }
      }
    }
  end

  # GET /api/artists/:artist_slug/vods/:id - Get a single VOD
  def vod_show
    @artist = Artist.find_by!(slug: params[:artist_slug])
    @stream = @artist.hackr_streams.find(params[:id])

    render json: {
      id: @stream.id,
      title: @stream.title,
      vod_url: @stream.vod_url,
      live_url: @stream.live_url,
      started_at: @stream.started_at,
      ended_at: @stream.ended_at,
      was_livestream: @stream.live_url.present?,
      artist: {
        id: @artist.id,
        name: @artist.name,
        slug: @artist.slug
      }
    }
  end

  # POST /api/artists/:artist_slug/vods/:id/watch
  def watch
    return head :no_content unless current_hackr

    artist = Artist.find_by!(slug: params[:artist_slug])
    stream = artist.hackr_streams.find(params[:id])

    HackrVodWatch.record!(current_hackr, stream)
    Grid::AchievementChecker.new(current_hackr).check("vods_watched")

    head :no_content
  end

  private

  def record_not_found
    render json: {error: "Not found"}, status: :not_found
  end
end
