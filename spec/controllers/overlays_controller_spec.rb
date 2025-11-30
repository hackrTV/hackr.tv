require "rails_helper"

RSpec.describe OverlaysController, type: :controller do
  describe "GET #now_playing" do
    it "returns success" do
      get :now_playing
      expect(response).to have_http_status(:ok)
    end

    it "loads current now playing" do
      get :now_playing
      expect(assigns(:now_playing)).to eq(OverlayNowPlaying.current)
    end

    it "uses overlay layout" do
      get :now_playing
      expect(response).to render_template(layout: "overlay")
    end
  end

  describe "GET #pulsewire" do
    let(:hackr) { create(:grid_hackr) }

    it "returns success" do
      get :pulsewire
      expect(response).to have_http_status(:ok)
    end

    it "loads recent pulses" do
      pulse = create(:pulse, grid_hackr: hackr)
      get :pulsewire
      expect(assigns(:pulses)).to include(pulse)
    end

    it "excludes signal-dropped pulses" do
      active_pulse = create(:pulse, grid_hackr: hackr)
      dropped_pulse = create(:pulse, :signal_dropped, grid_hackr: hackr)

      get :pulsewire

      expect(assigns(:pulses)).to include(active_pulse)
      expect(assigns(:pulses)).not_to include(dropped_pulse)
    end

    it "excludes splice pulses (only root pulses)" do
      root_pulse = create(:pulse, grid_hackr: hackr)
      splice_pulse = create(:pulse, grid_hackr: hackr, parent_pulse: root_pulse)

      get :pulsewire

      expect(assigns(:pulses)).to include(root_pulse)
      expect(assigns(:pulses)).not_to include(splice_pulse)
    end

    it "respects limit parameter" do
      create_list(:pulse, 10, grid_hackr: hackr)

      get :pulsewire, params: {limit: 3}

      expect(assigns(:pulses).count).to eq(3)
    end

    it "defaults to 5 pulses" do
      create_list(:pulse, 10, grid_hackr: hackr)

      get :pulsewire

      expect(assigns(:pulses).count).to eq(5)
    end
  end

  describe "GET #grid_activity" do
    let(:hackr) { create(:grid_hackr) }
    let(:room) { create(:grid_room) }

    it "returns success" do
      get :grid_activity
      expect(response).to have_http_status(:ok)
    end

    it "loads online hackrs" do
      online_hackr = create(:grid_hackr, current_room: room, last_activity_at: 5.minutes.ago)
      offline_hackr = create(:grid_hackr, current_room: room, last_activity_at: 30.minutes.ago)

      get :grid_activity

      expect(assigns(:online_hackrs)).to include(online_hackr)
      expect(assigns(:online_hackrs)).not_to include(offline_hackr)
    end

    it "loads recent messages" do
      message = create(:grid_message, grid_hackr: hackr)

      get :grid_activity

      expect(assigns(:recent_messages)).to include(message)
    end

    it "respects limit parameter for messages" do
      create_list(:grid_message, 10, grid_hackr: hackr)

      get :grid_activity, params: {limit: 3}

      expect(assigns(:recent_messages).count).to eq(3)
    end
  end

  describe "GET #alerts" do
    it "returns success" do
      get :alerts
      expect(response).to have_http_status(:ok)
    end

    it "loads oldest pending alert" do
      old_alert = create(:overlay_alert, created_at: 2.hours.ago)
      create(:overlay_alert, created_at: 1.hour.ago)

      get :alerts

      expect(assigns(:alert)).to eq(old_alert)
    end

    it "excludes displayed alerts" do
      pending_alert = create(:overlay_alert)
      create(:overlay_alert, :displayed)

      get :alerts

      expect(assigns(:alert)).to eq(pending_alert)
    end

    it "excludes expired alerts" do
      valid_alert = create(:overlay_alert, expires_at: 1.hour.from_now)
      create(:overlay_alert, :expired)

      get :alerts

      expect(assigns(:alert)).to eq(valid_alert)
    end
  end

  describe "GET #lower_third" do
    let!(:lower_third) { create(:overlay_lower_third, slug: "host", active: true) }

    it "returns success" do
      get :lower_third, params: {slug: "host"}
      expect(response).to have_http_status(:ok)
    end

    it "loads the lower third by slug" do
      get :lower_third, params: {slug: "host"}
      expect(assigns(:lower_third)).to eq(lower_third)
    end

    it "returns 404 for inactive lower third" do
      inactive = create(:overlay_lower_third, :inactive)
      expect {
        get :lower_third, params: {slug: inactive.slug}
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns 404 for non-existent slug" do
      expect {
        get :lower_third, params: {slug: "nonexistent"}
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET #codex" do
    let!(:entry) { create(:codex_entry, slug: "xeraen", published: true) }

    it "returns success" do
      get :codex, params: {slug: "xeraen"}
      expect(response).to have_http_status(:ok)
    end

    it "loads the codex entry by slug" do
      get :codex, params: {slug: "xeraen"}
      expect(assigns(:entry)).to eq(entry)
    end

    it "returns 404 for unpublished entry" do
      create(:codex_entry, slug: "draft", published: false)
      expect {
        get :codex, params: {slug: "draft"}
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET #ticker" do
    let!(:ticker) { create(:overlay_ticker, slug: "top", active: true) }

    it "returns success" do
      get :ticker, params: {position: "top"}
      expect(response).to have_http_status(:ok)
    end

    it "loads the ticker by position" do
      get :ticker, params: {position: "top"}
      expect(assigns(:ticker)).to eq(ticker)
    end

    it "returns 404 for inactive ticker" do
      create(:overlay_ticker, slug: "bottom", active: false)
      expect {
        get :ticker, params: {position: "bottom"}
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET #scene" do
    let!(:scene) { create(:overlay_scene, slug: "main", active: true) }

    it "returns success" do
      get :scene, params: {slug: "main"}
      expect(response).to have_http_status(:ok)
    end

    it "loads the scene by slug" do
      get :scene, params: {slug: "main"}
      expect(assigns(:scene)).to eq(scene)
    end

    it "loads scene elements" do
      element = create(:overlay_element)
      scene_element = create(:overlay_scene_element, overlay_scene: scene, overlay_element: element)

      get :scene, params: {slug: "main"}

      expect(assigns(:elements)).to include(scene_element)
    end

    it "returns 404 for inactive scene" do
      inactive = create(:overlay_scene, :inactive)
      expect {
        get :scene, params: {slug: inactive.slug}
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "uses fullscreen layout for fullscreen scenes" do
      create(:overlay_scene, slug: "fullscreen-test", scene_type: "fullscreen", active: true)

      get :scene, params: {slug: "fullscreen-test"}

      expect(response).to render_template(layout: "overlay_fullscreen")
    end

    it "uses regular overlay layout for composition scenes" do
      create(:overlay_scene, :composition, slug: "comp-test", active: true)

      get :scene, params: {slug: "comp-test"}

      expect(response).to render_template(layout: "overlay")
    end
  end
end
