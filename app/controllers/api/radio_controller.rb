module Api
  class RadioController < ApplicationController
    # GET /api/radio_stations
    def index
      # Load radio stations from config
      config = YAML.load_file(Rails.root.join("config", "radio_stations.yml"))
      render json: config["stations"]
    end
  end
end
