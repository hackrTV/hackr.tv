module Api
  class ArtistsController < ApplicationController
    # GET /api/artists
    def index
      @artists = Artist.all.order(:name)
      render json: @artists.map { |artist|
        {
          id: artist.id,
          name: artist.name,
          slug: artist.slug,
          genre: artist.genre,
          track_count: artist.tracks.count
        }
      }
    end

    # GET /api/artists/:id
    def show
      @artist = Artist.find_by(slug: params[:id]) || Artist.find(params[:id])

      render json: {
        id: @artist.id,
        name: @artist.name,
        slug: @artist.slug,
        genre: @artist.genre,
        tracks: @artist.tracks.includes(:album).order(Arel.sql("albums.release_date DESC NULLS LAST, tracks.track_number ASC")).map { |track|
          {
            id: track.id,
            title: track.title,
            slug: track.slug,
            track_number: track.track_number,
            duration: track.duration,
            featured: track.featured,
            streaming_links: track.streaming_links,
            album: track.album ? {
              id: track.album.id,
              name: track.album.name,
              slug: track.album.slug,
              album_type: track.album.album_type,
              release_date: track.album.release_date,
              cover_url: track.album.cover_image.attached? ? url_for(track.album.cover_image) : nil
            } : nil,
            audio_url: track.audio_file.attached? ? url_for(track.audio_file) : nil
          }
        }
      }
    end
  end
end
