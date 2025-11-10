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
    # Music discovery interface - show all tracks with custom ordering:
    # 1. The.CyberPul.se first, XERAEN second, others alphabetically
    # 2. Within artist, by album release_date (newest first)
    # 3. Within album, by track_number
    @tracks = Track.includes(:artist, :album).order(
      Arel.sql(<<-SQL.squish
        CASE
          WHEN artists.name = 'The.CyberPul.se' THEN 0
          WHEN artists.name = 'XERAEN' THEN 1
          ELSE 2
        END,
        CASE WHEN artists.name IN ('The.CyberPul.se', 'XERAEN') THEN '' ELSE artists.name END,
        albums.release_date DESC,
        tracks.track_number ASC
      SQL
      )
    ).joins(:artist, :album)
  end

  def bands
    # Bands directory with profiles
    @artists = Artist.order(:name)
  end
end
