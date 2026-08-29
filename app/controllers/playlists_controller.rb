# Playlist pages (Hotwire, Phase 4) — replace PlaylistsPage.tsx +
# PlaylistDetailPage.tsx. Page forms mutate through these thin actions
# (redirect + flash, Turbo-friendly); drag reorder still POSTs to the
# surviving Api::PlaylistsController#reorder endpoint from Stimulus.
class PlaylistsController < ApplicationController
  include GridAuthentication

  layout "hotwire"

  before_action :require_login
  before_action :set_playlist, only: %i[show update destroy remove_track]

  def index
    @playlists = current_hackr.playlists.includes(:playlist_tracks).order(created_at: :desc)
  end

  def show
    @tracks = @playlist.playlist_tracks.includes(track: [:artist, :release]).order(position: :asc)
    @autoplay = params[:autoplay] == "true"
  end

  def create
    playlist = current_hackr.playlists.build(playlist_params)
    if playlist.save
      redirect_to fm_playlist_path(playlist), status: :see_other
    else
      flash[:error] = playlist.errors.full_messages.to_sentence
      redirect_to fm_playlists_path, status: :see_other
    end
  end

  def update
    flash[:error] = @playlist.errors.full_messages.to_sentence unless @playlist.update(playlist_params)
    redirect_to fm_playlist_path(@playlist), status: :see_other
  end

  def destroy
    @playlist.destroy
    redirect_to fm_playlists_path, status: :see_other
  end

  def remove_track
    playlist_track = @playlist.playlist_tracks.find(params[:playlist_track_id])
    playlist_track.destroy
    redirect_to fm_playlist_path(@playlist), status: :see_other
  end

  private

  def set_playlist
    @playlist = current_hackr.playlists.find_by(id: params[:id])
    return if @playlist

    flash[:error] = "Playlist not found"
    redirect_to fm_playlists_path
  end

  def playlist_params
    params.require(:playlist).permit(:name, :description, :is_public)
  end
end
