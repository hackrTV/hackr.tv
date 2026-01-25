require "rails_helper"

RSpec.describe Admin::RadioStationsController, type: :controller do
  let(:admin_hackr) { create(:grid_hackr, role: "admin") }

  before do
    session[:grid_hackr_id] = admin_hackr.id
  end

  describe "GET #index" do
    it "returns success" do
      get :index
      expect(response).to have_http_status(:ok)
    end

    it "loads stations ordered by position" do
      station3 = create(:radio_station, position: 2)
      station1 = create(:radio_station, position: 0)
      station2 = create(:radio_station, position: 1)

      get :index

      expect(assigns(:radio_stations).to_a).to eq([station1, station2, station3])
    end

    it "includes associated playlists" do
      station = create(:radio_station)
      playlist = create(:playlist, grid_hackr: admin_hackr)
      create(:radio_station_playlist, radio_station: station, playlist: playlist)

      get :index

      expect(assigns(:radio_stations).first.playlists).to include(playlist)
    end
  end

  describe "GET #show" do
    let(:station) { create(:radio_station) }

    it "returns success" do
      get :show, params: {id: station.id}
      expect(response).to have_http_status(:ok)
    end

    it "loads the correct station" do
      get :show, params: {id: station.id}
      expect(assigns(:radio_station)).to eq(station)
    end
  end

  describe "authentication" do
    before do
      session[:grid_hackr_id] = nil
    end

    it "redirects non-admin users to grid" do
      get :index
      expect(response).to redirect_to(grid_path)
    end
  end
end
