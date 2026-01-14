module Api
  class PlaylistTracksController < ApplicationController
    include GridAuthentication

    before_action :require_login_api
    before_action :set_playlist
    before_action :authorize_playlist_owner

    # POST /api/playlists/:playlist_id/tracks
    def create
      track = Track.find(params[:track_id])

      # Check if track already exists in playlist
      if @playlist.tracks.include?(track)
        render json: {
          success: false,
          error: "This track is already in the playlist"
        }, status: :unprocessable_entity
        return
      end

      playlist_track = @playlist.playlist_tracks.build(track: track)

      if playlist_track.save
        render json: {
          success: true,
          message: "Track added to playlist",
          playlist_track: {
            id: playlist_track.id,
            position: playlist_track.position,
            track: {
              id: track.id,
              title: track.title,
              artist: {
                id: track.artist.id,
                name: track.artist.name
              }
            }
          }
        }, status: :created
      else
        render json: {
          success: false,
          error: playlist_track.errors.full_messages.join(", ")
        }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: {
        success: false,
        error: "Track not found"
      }, status: :not_found
    end

    # DELETE /api/playlists/:playlist_id/tracks/:id
    def destroy
      playlist_track = @playlist.playlist_tracks.find(params[:id])
      playlist_track.destroy

      # Reorder remaining tracks to fill the gap
      @playlist.playlist_tracks.where("position > ?", playlist_track.position).each do |pt|
        pt.update(position: pt.position - 1)
      end

      render json: {
        success: true,
        message: "Track removed from playlist"
      }
    rescue ActiveRecord::RecordNotFound
      render json: {
        success: false,
        error: "Track not found in this playlist"
      }, status: :not_found
    end

    # POST /api/playlists/:playlist_id/reorder
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
      @playlist = Playlist.find(params[:playlist_id])
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
        error: "You are not authorized to modify this playlist"
      }, status: :forbidden
    end
  end
end
