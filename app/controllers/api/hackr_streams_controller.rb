class Api::HackrStreamsController < ApplicationController
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
        url: @stream.url,
        started_at: @stream.started_at
      }
    else
      render json: {
        is_live: false
      }
    end
  end
end
