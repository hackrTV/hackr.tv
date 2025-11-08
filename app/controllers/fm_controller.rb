class FmController < ApplicationController
  layout "fm"

  def index
    redirect_to fm_radio_path
  end

  def radio
    # Load radio stations from config
    config = YAML.load_file(Rails.root.join("config", "radio_stations.yml"))
    @stations = config["stations"]
  end

  def pulse_vault
    # Music discovery interface - show all tracks
    @tracks = Track.includes(:artist).ordered
  end

  def bands
    # Bands directory with profiles
    @artists = Artist.order(:name)
  end
end
