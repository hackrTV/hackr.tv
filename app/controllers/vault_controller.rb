# Pulse Vault (Hotwire, Phase 4) — replaces PulseVaultPage.tsx.
class VaultController < ApplicationController
  include GridAuthentication

  def show
    @artist = Artist.find_by(slug: params[:artist].to_s)
    @tracks = Track.visible_in_pulse_vault
      .includes(:artist, release: {cover_image_attachment: :blob})
      .with_attached_audio_file
      .pulse_vault_ordered
    @tracks = @tracks.where(artist: @artist) if @artist
    @filter = params[:filter].to_s
  end
end
