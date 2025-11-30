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

    it "loads scenes" do
      scene = create(:overlay_scene)
      get :index
      expect(assigns(:scenes)).to include(scene)
    end

    it "loads elements" do
      element = create(:overlay_element)
      get :index
      expect(assigns(:elements)).to include(element)
    end

    it "loads lower thirds" do
      lower_third = create(:overlay_lower_third)
      get :index
      expect(assigns(:lower_thirds)).to include(lower_third)
    end

    it "loads tickers" do
      ticker = create(:overlay_ticker)
      get :index
      expect(assigns(:tickers)).to include(ticker)
    end

    it "loads now playing" do
      get :index
      expect(assigns(:now_playing)).to eq(OverlayNowPlaying.current)
    end

    it "loads tracks" do
      artist = create(:artist)
      track = create(:track, artist: artist)
      get :index
      expect(assigns(:tracks)).to include(track)
    end

    it "loads pending alerts count" do
      create(:overlay_alert, displayed: false)
      create(:overlay_alert, :displayed)
      get :index
      expect(assigns(:pending_alerts)).to eq(1)
    end
  end

  describe "PATCH #update_ticker" do
    let!(:ticker) { create(:overlay_ticker, slug: "top", content: "Original") }

    before do
      allow(ActionCable.server).to receive(:broadcast)
    end

    it "updates the ticker" do
      patch :update_ticker, params: {
        ticker_slug: "top",
        overlay_ticker: {content: "Updated content"}
      }

      ticker.reload
      expect(ticker.content).to eq("Updated content")
    end

    it "broadcasts update" do
      expect_any_instance_of(OverlayTicker).to receive(:broadcast_update!)
      patch :update_ticker, params: {
        ticker_slug: "top",
        overlay_ticker: {content: "New content"}
      }
    end

    it "redirects to index" do
      patch :update_ticker, params: {
        ticker_slug: "top",
        overlay_ticker: {content: "New"}
      }
      expect(response).to redirect_to(admin_overlays_path)
    end

    it "sets success flash" do
      patch :update_ticker, params: {
        ticker_slug: "top",
        overlay_ticker: {content: "New"}
      }
      expect(flash[:success]).to include(ticker.name)
    end

    it "sets error flash on invalid update" do
      patch :update_ticker, params: {
        ticker_slug: "top",
        overlay_ticker: {content: ""}
      }
      expect(flash[:error]).to be_present
    end
  end

  describe "POST #send_alert" do
    before do
      allow(ActionCable.server).to receive(:broadcast)
    end

    it "queues an alert" do
      expect {
        post :send_alert, params: {
          alert_type: "custom",
          alert_title: "Test Alert",
          alert_message: "Test message"
        }
      }.to change(OverlayAlert, :count).by(1)
    end

    it "sets default alert type to custom" do
      post :send_alert, params: {
        alert_title: "Test"
      }

      alert = OverlayAlert.last
      expect(alert.alert_type).to eq("custom")
    end

    it "redirects to index" do
      post :send_alert, params: {alert_title: "Test"}
      expect(response).to redirect_to(admin_overlays_path)
    end

    it "sets success flash" do
      post :send_alert, params: {alert_title: "Test"}
      expect(flash[:success]).to include("Alert sent")
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
