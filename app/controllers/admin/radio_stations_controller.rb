module Admin
  class RadioStationsController < ApplicationController
    before_action :set_radio_station, only: [:show, :edit, :update, :destroy, :add_playlist, :remove_playlist, :reorder_playlists]

    def index
      @radio_stations = RadioStation.ordered.includes(:playlists)
    end

    def show
      # Show all playlists owned by the current admin user (public or private)
      # that are not already assigned to this station
      @available_playlists = Playlist.where(grid_hackr_id: current_hackr.id)
                                     .where.not(id: @radio_station.playlists.pluck(:id))
                                     .order(:name)
    end

    def new
      @radio_station = RadioStation.new
      # Set position to be last
      @radio_station.position = RadioStation.maximum(:position).to_i + 1
    end

    def create
      @radio_station = RadioStation.new(radio_station_params)

      if @radio_station.save
        redirect_to admin_radio_station_path(@radio_station), notice: "Radio station created successfully."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @radio_station.update(radio_station_params)
        redirect_to admin_radio_station_path(@radio_station), notice: "Radio station updated successfully."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @radio_station.destroy
      redirect_to admin_radio_stations_path, notice: "Radio station deleted successfully."
    end

    def add_playlist
      playlist = Playlist.find(params[:playlist_id])

      @radio_station.radio_station_playlists.create!(playlist: playlist)

      redirect_to admin_radio_station_path(@radio_station), notice: "Playlist added to station."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_radio_station_path(@radio_station), alert: "Failed to add playlist: #{e.message}"
    end

    def remove_playlist
      radio_station_playlist = @radio_station.radio_station_playlists.find(params[:radio_station_playlist_id])
      radio_station_playlist.destroy

      redirect_to admin_radio_station_path(@radio_station), notice: "Playlist removed from station."
    end

    def reorder_playlists
      playlist_ids = params[:playlist_ids] || []

      playlist_ids.each_with_index do |playlist_id, index|
        rsp = @radio_station.radio_station_playlists.find_by(playlist_id: playlist_id)
        rsp&.update(position: index)
      end

      head :ok
    end

    private

    def set_radio_station
      @radio_station = RadioStation.find(params[:id])
    end

    def radio_station_params
      params.require(:radio_station).permit(:name, :slug, :description, :genre, :color, :stream_url, :position)
    end
  end
end
