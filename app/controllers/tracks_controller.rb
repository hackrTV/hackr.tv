class TracksController < ApplicationController
  # Legacy redirects for old /trackz routes
  # All track functionality now handled by React SPA via pages#spa_root

  # Legacy redirect for /trackz -> /thecyberpulse/trackz
  def legacy_redirect
    redirect_to thecyberpulse_tracks_path, status: 301
  end

  # Legacy redirect for /trackz/:id -> /thecyberpulse/trackz/:id
  def legacy_redirect_show
    redirect_to thecyberpulse_track_path(params[:id]), status: 301
  end
end
