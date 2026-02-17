module Api
  class ArtistsController < ApplicationController
    # GET /api/artists
    # Params: type (band/ost/voiceover) - defaults to "band" for backwards compatibility
    def index
      @artists = if params[:type].present? && Artist::ARTIST_TYPES.include?(params[:type])
        Artist.where(artist_type: params[:type])
      elsif params[:type] == "all"
        Artist.all
      else
        Artist.bands
      end

      render json: @artists.order(:name).map { |artist|
        {
          id: artist.id,
          name: artist.name,
          slug: artist.slug,
          genre: artist.genre,
          artist_type: artist.artist_type,
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
        tracks: @artist.tracks.visible_in_pulse_vault.includes(:release).order(Arel.sql("releases.release_date DESC NULLS LAST, tracks.track_number ASC")).joins(:release).map { |track|
          {
            id: track.id,
            title: track.title,
            slug: track.slug,
            track_number: track.track_number,
            duration: track.duration,
            featured: track.featured,
            streaming_links: track.streaming_links,
            release: if track.release
                       {
                         id: track.release.id,
                         name: track.release.name,
                         slug: track.release.slug,
                         release_type: track.release.release_type,
                         release_date: track.release.release_date,
                         cover_url: track.release.cover_image.attached? ? url_for(track.release.cover_image) : nil
                       }
                     end,
            audio_url: track.audio_file.attached? ? url_for(track.audio_file) : nil
          }
        }
      }
    end
  end
end
