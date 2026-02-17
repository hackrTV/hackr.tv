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
        tracks: @playlist.tracks.includes(:artist, :release).map do |track|
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
            release: if track.release
                       {
                         id: track.release.id,
                         name: track.release.name,
                         slug: track.release.slug,
                         cover_url: track.release.cover_image.attached? ? url_for(track.release.cover_image) : nil
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
