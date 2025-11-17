module Api
  class TracksController < ApplicationController
    # GET /api/tracks
    # GET /api/artists/:artist_id/tracks
    def index
      if params[:artist_id]
        # Get tracks for specific artist
        artist = Artist.find_by(slug: params[:artist_id]) || Artist.find(params[:artist_id])
        @tracks = artist.tracks.includes(:album).order("albums.release_date DESC NULLS LAST, tracks.track_number ASC").joins(:album)
      else
        # Get all tracks with Pulse Vault ordering
        @tracks = Track.includes(:artist, :album).order(
          Arel.sql(<<-SQL.squish
            CASE
              WHEN artists.name = 'The.CyberPul.se' THEN 0
              WHEN artists.name = 'XERAEN' THEN 1
              ELSE 2
            END,
            CASE WHEN artists.name IN ('The.CyberPul.se', 'XERAEN') THEN '' ELSE artists.name END,
            albums.release_date DESC,
            tracks.track_number ASC
          SQL
                  )
        ).joins(:artist, :album)
      end

      render json: @tracks.map { |track|
        {
          id: track.id,
          title: track.title,
          slug: track.slug,
          track_number: track.track_number,
          duration: track.duration,
          featured: track.featured,
          artist: {
            id: track.artist.id,
            name: track.artist.name,
            slug: track.artist.slug,
            genre: track.artist.genre
          },
          album: if track.album
                   {
                     id: track.album.id,
                     name: track.album.name,
                     slug: track.album.slug,
                     release_date: track.album.release_date,
                     cover_url: track.album.cover_image.attached? ? url_for(track.album.cover_image) : nil
                   }
                 end,
          audio_url: track.audio_file.attached? ? url_for(track.audio_file) : nil
        }
      }
    end

    # GET /api/tracks/:id
    def show
      @track = Track.includes(:artist, :album).find_by(slug: params[:id]) || Track.includes(:artist, :album).find(params[:id])

      render json: {
        id: @track.id,
        title: @track.title,
        slug: @track.slug,
        track_number: @track.track_number,
        duration: @track.duration,
        featured: @track.featured,
        release_date: @track.release_date,
        lyrics: @track.lyrics,
        streaming_links: @track.streaming_links,
        videos: @track.videos,
        artist: {
          id: @track.artist.id,
          name: @track.artist.name,
          slug: @track.artist.slug,
          genre: @track.artist.genre
        },
        album: if @track.album
                 {
                   id: @track.album.id,
                   name: @track.album.name,
                   slug: @track.album.slug,
                   album_type: @track.album.album_type,
                   release_date: @track.album.release_date,
                   description: @track.album.description,
                   cover_url: @track.album.cover_image.attached? ? url_for(@track.album.cover_image) : nil
                 }
               end,
        audio_url: @track.audio_file.attached? ? url_for(@track.audio_file) : nil
      }
    end
  end
end
