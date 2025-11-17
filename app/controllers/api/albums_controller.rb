module Api
  class AlbumsController < ApplicationController
    # GET /api/albums
    def index
      @albums = Album.includes(:artist).order("release_date DESC NULLS LAST")

      render json: @albums.map { |album|
        {
          id: album.id,
          name: album.name,
          slug: album.slug,
          album_type: album.album_type,
          release_date: album.release_date,
          description: album.description,
          artist: {
            id: album.artist.id,
            name: album.artist.name,
            slug: album.artist.slug,
            genre: album.artist.genre
          },
          cover_url: album.cover_image.attached? ? url_for(album.cover_image) : nil,
          track_count: album.tracks.count
        }
      }
    end

    # GET /api/albums/:id
    def show
      @album = Album.find_by(slug: params[:id]) || Album.find(params[:id])

      render json: {
        id: @album.id,
        name: @album.name,
        slug: @album.slug,
        album_type: @album.album_type,
        release_date: @album.release_date,
        description: @album.description,
        artist: {
          id: @album.artist.id,
          name: @album.artist.name,
          slug: @album.artist.slug,
          genre: @album.artist.genre
        },
        cover_url: @album.cover_image.attached? ? url_for(@album.cover_image) : nil,
        tracks: @album.tracks.order(:track_number, :title).map { |track|
          {
            id: track.id,
            title: track.title,
            slug: track.slug,
            track_number: track.track_number,
            duration: track.duration,
            audio_url: track.audio_file.attached? ? url_for(track.audio_file) : nil
          }
        }
      }
    end
  end
end
