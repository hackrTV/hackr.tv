module Api
  class PlaylistsController < ApplicationController
    include GridAuthentication

    before_action :require_login_api
    before_action :set_playlist, only: %i[show update destroy reorder]
    before_action :authorize_playlist_owner, only: %i[show update destroy reorder]

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
        tracks: @playlist.playlist_tracks.includes(track: %i[artist release]).map do |playlist_track|
          track = playlist_track.track
          {
            id: playlist_track.id, # This is the playlist_track ID we need for deletion
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
            release: if track.release
                       {
                         id: track.release.id,
                         name: track.release.name,
                         slug: track.release.slug,
                         cover_url: track.release.cover_image.attached? ? url_for(track.release.cover_image) : nil,
                         cover_urls: cover_urls_for(track.release)
                       }
                     end,
            audio_url: track.audio_file.attached? ? url_for(track.audio_file) : nil
          }
        end
      }
    end

    # POST /api/playlists
    def create
      @playlist = current_hackr.playlists.build(playlist_params)

      if @playlist.save
        # Note: `playlists_created` achievement requires ≥1 track — fires
        # from PlaylistTracksController#create after the first track add.
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

      track_ids = track_ids.map(&:to_i)

      if track_ids.uniq.length != track_ids.length
        render json: {
          success: false,
          error: "track_ids must be unique"
        }, status: :unprocessable_entity
        return
      end

      playlist_track_ids = @playlist.playlist_tracks.where(track_id: track_ids).pluck(:track_id)
      missing_ids = track_ids - playlist_track_ids
      if missing_ids.any?
        render json: {
          success: false,
          error: "track_ids contain tracks not in this playlist"
        }, status: :unprocessable_entity
        return
      end

      PlaylistTrack.transaction do
        track_ids.each_with_index do |track_id, index|
          playlist_track = @playlist.playlist_tracks.find_by!(track_id: track_id)
          playlist_track.update!(position: index + 1)
        end
      end

      render json: {
        success: true,
        message: "Playlist reordered successfully"
      }
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      render json: {
        success: false,
        error: e.message
      }, status: :unprocessable_entity
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
      return if @playlist.grid_hackr_id == current_hackr.id

      render json: {
        success: false,
        error: "You are not authorized to access this playlist"
      }, status: :forbidden
    end

    def playlist_params
      params.require(:playlist).permit(:name, :description, :is_public)
    end
  end
end
