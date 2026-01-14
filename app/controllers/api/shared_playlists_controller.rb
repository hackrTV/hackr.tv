module Api
  class SharedPlaylistsController < ApplicationController
    # GET /api/shared_playlists/:share_token
    def show
      @playlist = Playlist.find_by!(share_token: params[:share_token], is_public: true)

      render json: {
        id: @playlist.id,
        name: @playlist.name,
        description: @playlist.description,
        created_at: @playlist.created_at,
        track_count: @playlist.track_count,
        owner: {
          hackr_alias: @playlist.grid_hackr.hackr_alias
        },
        tracks: @playlist.tracks.includes(:artist, :album).map do |track|
          {
            id: track.id,
            title: track.title,
            slug: track.slug,
            track_number: track.track_number,
            duration: track.duration,
            artist: {
              id: track.artist.id,
              name: track.artist.name,
              slug: track.artist.slug
            },
            album: if track.album
                     {
                       id: track.album.id,
                       name: track.album.name,
                       slug: track.album.slug,
                       cover_url: track.album.cover_image.attached? ? url_for(track.album.cover_image) : nil
                     }
                   end,
            audio_url: track.audio_file.attached? ? url_for(track.audio_file) : nil
          }
        end
      }
    rescue ActiveRecord::RecordNotFound
      render json: {
        success: false,
        error: "Shared playlist not found or not public"
      }, status: :not_found
    end
  end
end
