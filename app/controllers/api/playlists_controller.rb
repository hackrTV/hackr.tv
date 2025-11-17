module Api
  class PlaylistsController < ApplicationController
    include GridAuthentication

    skip_before_action :verify_authenticity_token
    before_action :require_login_api
    before_action :set_playlist, only: [:show, :update, :destroy, :reorder]
    before_action :authorize_playlist_owner, only: [:show, :update, :destroy, :reorder]

    # GET /api/playlists
    def index
      @playlists = current_hackr.playlists.includes(:playlist_tracks)

      render json: @playlists.map { |playlist|
        {
          id: playlist.id,
          name: playlist.name,
          description: playlist.description,
          is_public: playlist.is_public,
          share_token: playlist.share_token,
          created_at: playlist.created_at,
          track_count: playlist.track_count
        }
      }
    end

    # GET /api/playlists/:id
    def show
      render json: {
        id: @playlist.id,
        name: @playlist.name,
        description: @playlist.description,
        is_public: @playlist.is_public,
        share_token: @playlist.share_token,
        created_at: @playlist.created_at,
        track_count: @playlist.track_count,
        tracks: @playlist.playlist_tracks.includes(track: [:artist, :album]).map { |playlist_track|
          track = playlist_track.track
          {
            id: playlist_track.id,  # This is the playlist_track ID we need for deletion
            track_id: track.id,
            title: track.title,
            slug: track.slug,
            track_number: track.track_number,
            duration: track.duration,
            position: playlist_track.position,
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
        }
      }
    end

    # POST /api/playlists
    def create
      @playlist = current_hackr.playlists.build(playlist_params)

      if @playlist.save
        render json: {
          success: true,
          message: "Playlist created successfully",
          playlist: {
            id: @playlist.id,
            name: @playlist.name,
            description: @playlist.description,
            is_public: @playlist.is_public,
            share_token: @playlist.share_token,
            created_at: @playlist.created_at,
            track_count: 0
          }
        }, status: :created
      else
        render json: {
          success: false,
          error: @playlist.errors.full_messages.join(", ")
        }, status: :unprocessable_entity
      end
    end

    # PATCH /api/playlists/:id
    def update
      if @playlist.update(playlist_params)
        render json: {
          success: true,
          message: "Playlist updated successfully",
          playlist: {
            id: @playlist.id,
            name: @playlist.name,
            description: @playlist.description,
            is_public: @playlist.is_public,
            share_token: @playlist.share_token,
            created_at: @playlist.created_at,
            track_count: @playlist.track_count
          }
        }
      else
        render json: {
          success: false,
          error: @playlist.errors.full_messages.join(", ")
        }, status: :unprocessable_entity
      end
    end

    # DELETE /api/playlists/:id
    def destroy
      @playlist.destroy
      render json: {
        success: true,
        message: "Playlist deleted successfully"
      }
    end

    # POST /api/playlists/:id/reorder
    def reorder
      track_ids = params[:track_ids]

      unless track_ids.is_a?(Array)
        render json: {
          success: false,
          error: "track_ids must be an array"
        }, status: :unprocessable_entity
        return
      end

      # Update positions based on the order in track_ids array
      track_ids.each_with_index do |track_id, index|
        playlist_track = @playlist.playlist_tracks.find_by(track_id: track_id)
        playlist_track&.update(position: index + 1)
      end

      render json: {
        success: true,
        message: "Playlist reordered successfully"
      }
    end

    private

    def set_playlist
      @playlist = Playlist.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: {
        success: false,
        error: "Playlist not found"
      }, status: :not_found
    end

    def authorize_playlist_owner
      unless @playlist.grid_hackr_id == current_hackr.id
        render json: {
          success: false,
          error: "You are not authorized to access this playlist"
        }, status: :forbidden
      end
    end

    def playlist_params
      params.require(:playlist).permit(:name, :description, :is_public)
    end
  end
end
