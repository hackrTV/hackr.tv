class Api::HackrStreamsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  # GET /api/hackr_stream - Get current live stream + next scheduled
  def show
    @stream = HackrStream.includes(:artist).current_live
    @next_scheduled = HackrStream.includes(:artist).next_scheduled

    response = if @stream
      {
        is_live: true,
        id: @stream.id,
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
      {is_live: false}
    end

    response[:next_scheduled] = @next_scheduled&.scheduled_json

    render json: response
  end

  # GET /api/streams/schedule - Public schedule page data
  def schedule
    upcoming = HackrStream.includes(:artist).upcoming.limit(20)
    past = HackrStream.includes(:artist).past_broadcasts.limit(20)

    render json: {
      upcoming: upcoming.map { |s| schedule_stream_json(s) },
      past: past.map { |s| schedule_stream_json(s) }
    }
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

  def schedule_stream_json(stream)
    {
      id: stream.id,
      title: stream.title,
      artist: {
        id: stream.artist.id,
        name: stream.artist.name,
        slug: stream.artist.slug
      },
      scheduled_at: stream.scheduled_at&.iso8601,
      started_at: stream.started_at&.iso8601,
      ended_at: stream.ended_at&.iso8601,
      vod_url: stream.vod_url,
      display_state: stream.display_state.to_s
    }
  end
end
