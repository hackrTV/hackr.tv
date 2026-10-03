require "rails_helper"

RSpec.describe Admin::OverlaysController, type: :controller do
  let(:admin_hackr) { create(:grid_hackr, role: "admin") }

  before do
    session[:grid_hackr_id] = admin_hackr.id
  end

  describe "GET #index" do
    it "returns success" do
      get :index
      expect(response).to have_http_status(:ok)
    end

    it "loads now playing" do
      get :index
      expect(assigns(:now_playing)).to eq(OverlayNowPlaying.current)
    end

    it "loads pending alerts count" do
      create(:overlay_alert, displayed: false)
      create(:overlay_alert, :displayed)
      get :index
      expect(assigns(:pending_alerts)).to eq(1)
    end

    context "with views rendered" do
      render_views

      it "renders the HUD data dashboard" do
        get :index
        expect(response.body).to include("HUD DATA SURFACE")
        expect(response.body).to include("/api/overlay/now-playing")
      end
    end
  end

  describe "GET #edit_now_playing" do
    it "returns success" do
      get :edit_now_playing
      expect(response).to have_http_status(:ok)
    end

    context "with views rendered" do
      render_views

      it "links the now-playing API JSON instead of the retired preview page" do
        get :edit_now_playing
        expect(response.body).to include("/api/overlay/now-playing")
        expect(response.body).not_to include('href="/overlays/now-playing"')
      end
    end

    it "loads now playing" do
      get :edit_now_playing
      expect(assigns(:now_playing)).to eq(OverlayNowPlaying.current)
    end

    it "loads tracks" do
      artist = create(:artist)
      track = create(:track, artist: artist)
      get :edit_now_playing
      expect(assigns(:tracks)).to include(track)
    end
  end

  describe "PATCH #update_now_playing" do
    before do
      allow(ActionCable.server).to receive(:broadcast)
    end

    it "sets track and broadcasts" do
      artist = create(:artist)
      track = create(:track, artist: artist)

      patch :update_now_playing, params: {
        overlay_now_playing: {track_id: track.id, paused: "0"}
      }

      np = OverlayNowPlaying.current
      expect(np.track).to eq(track)
      expect(flash[:success]).to include(track.title)
      expect(response).to redirect_to(admin_edit_overlay_now_playing_path)
    end

    it "sets custom title and broadcasts" do
      patch :update_now_playing, params: {
        overlay_now_playing: {custom_title: "Test Song", custom_artist: "Test Artist"}
      }

      np = OverlayNowPlaying.current
      expect(np.custom_title).to eq("Test Song")
      expect(flash[:success]).to include("custom track")
      expect(response).to redirect_to(admin_edit_overlay_now_playing_path)
    end

    it "clears now playing" do
      patch :update_now_playing, params: {clear: "1"}

      np = OverlayNowPlaying.current
      expect(np.playing?).to be false
      expect(flash[:success]).to include("cleared")
      expect(response).to redirect_to(admin_edit_overlay_now_playing_path)
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

    it "redirects regular users to grid" do
      regular_user = create(:grid_hackr, role: "operative")
      session[:grid_hackr_id] = regular_user.id

      get :index
      expect(response).to redirect_to(grid_path)
    end
  end
end
