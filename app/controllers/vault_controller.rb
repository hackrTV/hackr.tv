# Pulse Vault (Hotwire, Phase 4) — replaces PulseVaultPage.tsx.
class VaultController < ApplicationController
  include GridAuthentication

  def show
    @tracks = Track.visible_in_pulse_vault
      .includes(:artist, release: {cover_image_attachment: :blob})
      .with_attached_audio_file
      .pulse_vault_ordered
    @filter = params[:filter].to_s
  end
end
