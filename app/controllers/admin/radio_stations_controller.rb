# Read-only controller - Radio stations are managed via YAML files
# Edit data/system/radio_stations.yml and run: rails data:radio_stations
module Admin
  class RadioStationsController < ApplicationController
    def index
      @radio_stations = RadioStation.ordered.includes(:playlists)
    end

    def show
      @radio_station = RadioStation.find(params[:id])
    end
  end
end
