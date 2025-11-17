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

    it "loads available playlists for current user" do
      my_playlist = create(:playlist, grid_hackr: admin_hackr)
      other_playlist = create(:playlist, grid_hackr: create(:grid_hackr))

      get :show, params: {id: station.id}

      expect(assigns(:available_playlists)).to include(my_playlist)
      expect(assigns(:available_playlists)).not_to include(other_playlist)
    end

    it "excludes playlists already assigned to station" do
      assigned_playlist = create(:playlist, grid_hackr: admin_hackr)
      unassigned_playlist = create(:playlist, grid_hackr: admin_hackr)

      create(:radio_station_playlist, radio_station: station, playlist: assigned_playlist)

      get :show, params: {id: station.id}

      expect(assigns(:available_playlists)).to include(unassigned_playlist)
      expect(assigns(:available_playlists)).not_to include(assigned_playlist)
    end
  end

  describe "GET #new" do
    it "returns success" do
      get :new
      expect(response).to have_http_status(:ok)
    end

    it "builds a new station" do
      get :new
      expect(assigns(:radio_station)).to be_a_new(RadioStation)
    end

    it "sets position to next available" do
      create(:radio_station, position: 5)

      get :new

      expect(assigns(:radio_station).position).to eq(6)
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        radio_station: {
          name: "New Station",
          slug: "new-station",
          description: "Test description",
          genre: "Electronic",
          color: "purple-168",
          stream_url: "http://example.com/stream",
          position: 0
        }
      }
    end

    it "creates a new station" do
      expect {
        post :create, params: valid_params
      }.to change(RadioStation, :count).by(1)
    end

    it "redirects to show page on success" do
      post :create, params: valid_params
      expect(response).to redirect_to(admin_radio_station_path(RadioStation.last))
    end

    it "renders new template on failure" do
      invalid_params = {radio_station: {name: ""}}
      post :create, params: invalid_params
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template(:new)
    end
  end

  describe "GET #edit" do
    let(:station) { create(:radio_station) }

    it "returns success" do
      get :edit, params: {id: station.id}
      expect(response).to have_http_status(:ok)
    end

    it "loads the correct station" do
      get :edit, params: {id: station.id}
      expect(assigns(:radio_station)).to eq(station)
    end
  end

  describe "PATCH #update" do
    let(:station) { create(:radio_station, name: "Old Name") }

    it "updates the station" do
      patch :update, params: {
        id: station.id,
        radio_station: {name: "New Name"}
      }

      station.reload
      expect(station.name).to eq("New Name")
    end

    it "redirects to show page on success" do
      patch :update, params: {
        id: station.id,
        radio_station: {name: "New Name"}
      }

      expect(response).to redirect_to(admin_radio_station_path(station))
    end

    it "renders edit template on failure" do
      patch :update, params: {
        id: station.id,
        radio_station: {name: ""}
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response).to render_template(:edit)
    end
  end

  describe "DELETE #destroy" do
    let!(:station) { create(:radio_station) }

    it "destroys the station" do
      expect {
        delete :destroy, params: {id: station.id}
      }.to change(RadioStation, :count).by(-1)
    end

    it "redirects to index" do
      delete :destroy, params: {id: station.id}
      expect(response).to redirect_to(admin_radio_stations_path)
    end

    it "cascades delete to station playlists" do
      playlist = create(:playlist, grid_hackr: admin_hackr)
      create(:radio_station_playlist, radio_station: station, playlist: playlist)

      expect {
        delete :destroy, params: {id: station.id}
      }.to change(RadioStationPlaylist, :count).by(-1)
    end
  end

  describe "POST #add_playlist" do
    let(:station) { create(:radio_station) }
    let(:playlist) { create(:playlist, grid_hackr: admin_hackr) }

    it "adds playlist to station" do
      expect {
        post :add_playlist, params: {id: station.id, playlist_id: playlist.id}
      }.to change(station.radio_station_playlists, :count).by(1)
    end

    it "assigns auto-incrementing position" do
      existing_playlist = create(:playlist, grid_hackr: admin_hackr)
      create(:radio_station_playlist, radio_station: station, playlist: existing_playlist, position: 1)

      post :add_playlist, params: {id: station.id, playlist_id: playlist.id}

      rsp = station.radio_station_playlists.find_by(playlist: playlist)
      expect(rsp.position).to eq(2)
    end

    it "redirects to station show page" do
      post :add_playlist, params: {id: station.id, playlist_id: playlist.id}
      expect(response).to redirect_to(admin_radio_station_path(station))
    end

    it "handles duplicate playlist error" do
      create(:radio_station_playlist, radio_station: station, playlist: playlist)

      post :add_playlist, params: {id: station.id, playlist_id: playlist.id}

      expect(response).to redirect_to(admin_radio_station_path(station))
      expect(flash[:alert]).to include("Failed to add playlist")
    end
  end

  describe "DELETE #remove_playlist" do
    let(:station) { create(:radio_station) }
    let(:playlist) { create(:playlist, grid_hackr: admin_hackr) }
    let!(:rsp) { create(:radio_station_playlist, radio_station: station, playlist: playlist) }

    it "removes playlist from station" do
      expect {
        delete :remove_playlist, params: {
          id: station.id,
          radio_station_playlist_id: rsp.id
        }
      }.to change(station.radio_station_playlists, :count).by(-1)
    end

    it "does not delete the playlist itself" do
      expect {
        delete :remove_playlist, params: {
          id: station.id,
          radio_station_playlist_id: rsp.id
        }
      }.not_to change(Playlist, :count)
    end

    it "redirects to station show page" do
      delete :remove_playlist, params: {
        id: station.id,
        radio_station_playlist_id: rsp.id
      }
      expect(response).to redirect_to(admin_radio_station_path(station))
    end
  end

  describe "POST #reorder_playlists" do
    let(:station) { create(:radio_station) }
    let(:playlist1) { create(:playlist, grid_hackr: admin_hackr) }
    let(:playlist2) { create(:playlist, grid_hackr: admin_hackr) }
    let(:playlist3) { create(:playlist, grid_hackr: admin_hackr) }

    before do
      create(:radio_station_playlist, radio_station: station, playlist: playlist1, position: 1)
      create(:radio_station_playlist, radio_station: station, playlist: playlist2, position: 2)
      create(:radio_station_playlist, radio_station: station, playlist: playlist3, position: 3)
    end

    it "reorders playlists based on array order" do
      # Reverse the order
      post :reorder_playlists, params: {
        id: station.id,
        playlist_ids: [playlist3.id, playlist2.id, playlist1.id]
      }, format: :json

      station.reload
      playlists_ordered = station.radio_station_playlists.order(position: :asc).map(&:playlist)

      expect(playlists_ordered[0]).to eq(playlist3)
      expect(playlists_ordered[1]).to eq(playlist2)
      expect(playlists_ordered[2]).to eq(playlist1)
    end

    it "returns ok status" do
      post :reorder_playlists, params: {
        id: station.id,
        playlist_ids: [playlist1.id, playlist2.id, playlist3.id]
      }, format: :json

      expect(response).to have_http_status(:ok)
    end

    it "handles partial playlist list" do
      # Only reorder first two
      post :reorder_playlists, params: {
        id: station.id,
        playlist_ids: [playlist2.id, playlist1.id]
      }, format: :json

      rsp1 = station.radio_station_playlists.find_by(playlist: playlist1)
      rsp2 = station.radio_station_playlists.find_by(playlist: playlist2)

      expect(rsp2.position).to eq(1)
      expect(rsp1.position).to eq(2)
      # playlist3 position unchanged
    end
  end
end
