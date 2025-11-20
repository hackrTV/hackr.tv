class AddShowInPulseVaultToTracks < ActiveRecord::Migration[8.1]
  def change
    add_column :tracks, :show_in_pulse_vault, :boolean, default: true, null: false
  end
end
