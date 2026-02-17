class Api::OverlayController < ApplicationController
  include GridAuthentication

  # POST /api/overlay/now-playing
  # Called by the React player when a track starts playing, pauses, or resumes
  def set_now_playing
    if params[:track_id].present?
      track = Track.find_by(id: params[:track_id])
      if track
        paused = params[:paused] == true || params[:paused] == "true"
        OverlayNowPlaying.set_track!(track, paused: paused)
        render json: {
          success: true,
          now_playing: {
            track_id: track.id,
            title: track.title,
            artist: track.artist&.name,
            album: track.release&.name,
            paused: paused
          }
        }
      else
        render json: {success: false, error: "Track not found"}, status: :not_found
      end
    elsif params.key?(:paused) && params[:track_id].nil?
      # Update paused state for current track
      paused = params[:paused] == true || params[:paused] == "true"
      OverlayNowPlaying.set_paused!(paused)
      render json: {success: true, paused: paused}
    elsif params[:clear].present?
      OverlayNowPlaying.clear!
      render json: {success: true, now_playing: nil}
    else
      render json: {success: false, error: "Missing track_id, paused, or clear parameter"}, status: :bad_request
    end
  end
end
