require "rails_helper"

RSpec.describe Admin::PulseWireController, type: :controller do
  let(:admin_hackr) { create(:grid_hackr, :admin) }
  let(:user_hackr) { create(:grid_hackr) }

  before do
    session[:grid_hackr_id] = admin_hackr.id
  end

  describe "GET #index" do
    it "returns success" do
      get :index
      expect(response).to have_http_status(:ok)
    end

    it "loads all pulses by default" do
      pulse1 = create(:pulse, grid_hackr: user_hackr)
      pulse2 = create(:pulse, grid_hackr: admin_hackr)
      pulse3 = create(:pulse, :signal_dropped, grid_hackr: user_hackr)

      get :index

      expect(assigns(:pulses)).to include(pulse1, pulse2, pulse3)
    end

    it "orders pulses by pulsed_at descending" do
      pulse1 = create(:pulse, grid_hackr: user_hackr, pulsed_at: 2.days.ago)
      pulse2 = create(:pulse, grid_hackr: user_hackr, pulsed_at: 1.day.ago)
      pulse3 = create(:pulse, grid_hackr: user_hackr, pulsed_at: 3.days.ago)

      get :index

      expect(assigns(:pulses).to_a).to eq([pulse2, pulse1, pulse3])
    end

    context "with status filter" do
      let!(:active_pulse) { create(:pulse, grid_hackr: user_hackr) }
      let!(:dropped_pulse) { create(:pulse, :signal_dropped, grid_hackr: user_hackr) }

      it "filters to active pulses only" do
        get :index, params: {status: "active"}

        expect(assigns(:pulses)).to include(active_pulse)
        expect(assigns(:pulses)).not_to include(dropped_pulse)
      end

      it "filters to dropped pulses only" do
        get :index, params: {status: "dropped"}

        expect(assigns(:pulses)).to include(dropped_pulse)
        expect(assigns(:pulses)).not_to include(active_pulse)
      end
    end

    context "with username filter" do
      let!(:pulse1) { create(:pulse, grid_hackr: user_hackr) }
      let!(:pulse2) { create(:pulse, grid_hackr: admin_hackr) }

      it "filters pulses by username" do
        get :index, params: {username: user_hackr.hackr_alias}

        expect(assigns(:pulses)).to include(pulse1)
        expect(assigns(:pulses)).not_to include(pulse2)
      end

      it "returns empty if username not found" do
        get :index, params: {username: "nonexistent"}

        expect(assigns(:pulses)).to be_empty
      end
    end

    context "with content search" do
      let!(:pulse1) { create(:pulse, grid_hackr: user_hackr, content: "The Grid is alive") }
      let!(:pulse2) { create(:pulse, grid_hackr: user_hackr, content: "Signal received") }

      it "filters pulses by content search" do
        get :index, params: {search: "Grid"}

        expect(assigns(:pulses)).to include(pulse1)
        expect(assigns(:pulses)).not_to include(pulse2)
      end

      it "is case insensitive" do
        get :index, params: {search: "grid"}

        expect(assigns(:pulses)).to include(pulse1)
      end
    end

    context "with date range filter" do
      let!(:old_pulse) { create(:pulse, grid_hackr: user_hackr, pulsed_at: 10.days.ago) }
      let!(:recent_pulse) { create(:pulse, grid_hackr: user_hackr, pulsed_at: 1.day.ago) }

      it "filters by start date" do
        get :index, params: {start_date: 5.days.ago.to_date}

        expect(assigns(:pulses)).to include(recent_pulse)
        expect(assigns(:pulses)).not_to include(old_pulse)
      end

      it "filters by end date" do
        get :index, params: {end_date: 5.days.ago.to_date}

        expect(assigns(:pulses)).to include(old_pulse)
        expect(assigns(:pulses)).not_to include(recent_pulse)
      end

      it "filters by date range" do
        mid_pulse = create(:pulse, grid_hackr: user_hackr, pulsed_at: 3.days.ago)

        get :index, params: {
          start_date: 5.days.ago.to_date,
          end_date: 2.days.ago.to_date
        }

        expect(assigns(:pulses)).to include(mid_pulse)
        expect(assigns(:pulses)).not_to include(old_pulse)
        expect(assigns(:pulses)).not_to include(recent_pulse)
      end
    end
  end

  describe "GET #signal_drops" do
    let!(:active_pulse) { create(:pulse, grid_hackr: user_hackr) }
    let!(:dropped_pulse) { create(:pulse, :signal_dropped, grid_hackr: user_hackr) }

    it "returns success" do
      get :signal_drops
      expect(response).to have_http_status(:ok)
    end

    it "loads only signal-dropped pulses" do
      get :signal_drops

      expect(assigns(:pulses)).to include(dropped_pulse)
      expect(assigns(:pulses)).not_to include(active_pulse)
    end

    it "orders by pulsed_at descending" do
      create(:pulse, :signal_dropped, grid_hackr: user_hackr, pulsed_at: 3.days.ago)
      create(:pulse, :signal_dropped, grid_hackr: user_hackr, pulsed_at: 1.day.ago)
      create(:pulse, :signal_dropped, grid_hackr: user_hackr, pulsed_at: 2.days.ago)

      get :signal_drops

      # Ensure correct ordering: most recent first
      pulses = assigns(:pulses).to_a
      expect(pulses[0].pulsed_at).to be > pulses[1].pulsed_at
      expect(pulses[1].pulsed_at).to be > pulses[2].pulsed_at
    end
  end

  describe "POST #signal_drop" do
    let!(:pulse) { create(:pulse, grid_hackr: user_hackr) }

    it "marks the pulse as signal-dropped" do
      expect {
        post :signal_drop, params: {id: pulse.id}
        pulse.reload
      }.to change { pulse.signal_dropped }.from(false).to(true)
    end

    it "sets signal_dropped_at timestamp" do
      post :signal_drop, params: {id: pulse.id}
      pulse.reload

      expect(pulse.signal_dropped_at).to be_present
      expect(pulse.signal_dropped_at).to be_within(1.second).of(Time.current)
    end

    it "redirects back with success flash" do
      post :signal_drop, params: {id: pulse.id}

      expect(response).to redirect_to(admin_pulse_wire_index_path)
      expect(flash[:success]).to include("signal-dropped")
    end
  end

  describe "POST #restore" do
    let!(:dropped_pulse) { create(:pulse, :signal_dropped, grid_hackr: user_hackr) }

    it "restores the pulse" do
      expect {
        post :restore, params: {id: dropped_pulse.id}
        dropped_pulse.reload
      }.to change { dropped_pulse.signal_dropped }.from(true).to(false)
    end

    it "clears signal_dropped_at timestamp" do
      post :restore, params: {id: dropped_pulse.id}
      dropped_pulse.reload

      expect(dropped_pulse.signal_dropped_at).to be_nil
    end

    it "redirects back with success flash" do
      post :restore, params: {id: dropped_pulse.id}

      expect(response).to redirect_to(signal_drops_admin_pulse_wire_index_path)
      expect(flash[:success]).to include("restored")
    end
  end

  describe "DELETE #destroy" do
    let!(:pulse) { create(:pulse, grid_hackr: user_hackr) }

    it "permanently deletes the pulse" do
      expect {
        delete :destroy, params: {id: pulse.id}
      }.to change(Pulse, :count).by(-1)
    end

    it "redirects back with success flash" do
      delete :destroy, params: {id: pulse.id}

      expect(response).to redirect_to(admin_pulse_wire_index_path)
      expect(flash[:success]).to include("permanently deleted")
    end

    it "cascades to echoes" do
      create(:echo, pulse: pulse, grid_hackr: admin_hackr)

      expect {
        delete :destroy, params: {id: pulse.id}
      }.to change(Echo, :count).by(-1)
    end

    it "cascades to splices" do
      create(:pulse, parent_pulse: pulse, grid_hackr: user_hackr)

      expect {
        delete :destroy, params: {id: pulse.id}
      }.to change(Pulse, :count).by(-2) # parent + splice
    end
  end

  describe "POST #bulk_signal_drop" do
    let!(:pulse1) { create(:pulse, grid_hackr: user_hackr) }
    let!(:pulse2) { create(:pulse, grid_hackr: user_hackr) }
    let!(:pulse3) { create(:pulse, grid_hackr: admin_hackr) }

    it "signal-drops multiple pulses" do
      post :bulk_signal_drop, params: {pulse_ids: [pulse1.id, pulse2.id]}

      pulse1.reload
      pulse2.reload
      pulse3.reload

      expect(pulse1.signal_dropped).to be true
      expect(pulse2.signal_dropped).to be true
      expect(pulse3.signal_dropped).to be false
    end

    it "sets flash with count" do
      post :bulk_signal_drop, params: {pulse_ids: [pulse1.id, pulse2.id]}

      expect(flash[:success]).to match(/Signal-dropped 2 pulses/)
    end

    it "shows error if no pulses selected" do
      post :bulk_signal_drop, params: {pulse_ids: []}

      expect(flash[:error]).to include("No pulses selected")
    end

    it "handles singular vs plural flash message" do
      post :bulk_signal_drop, params: {pulse_ids: [pulse1.id]}

      expect(flash[:success]).to match(/Signal-dropped 1 pulse\./)
    end

    it "redirects back" do
      post :bulk_signal_drop, params: {pulse_ids: [pulse1.id]}

      expect(response).to redirect_to(admin_pulse_wire_index_path)
    end
  end

  describe "DELETE #bulk_destroy" do
    let!(:pulse1) { create(:pulse, grid_hackr: user_hackr) }
    let!(:pulse2) { create(:pulse, grid_hackr: user_hackr) }
    let!(:pulse3) { create(:pulse, grid_hackr: admin_hackr) }

    it "permanently deletes multiple pulses" do
      expect {
        delete :bulk_destroy, params: {pulse_ids: [pulse1.id, pulse2.id]}
      }.to change(Pulse, :count).by(-2)

      expect(Pulse.exists?(pulse1.id)).to be false
      expect(Pulse.exists?(pulse2.id)).to be false
      expect(Pulse.exists?(pulse3.id)).to be true
    end

    it "sets flash with count" do
      delete :bulk_destroy, params: {pulse_ids: [pulse1.id, pulse2.id]}

      expect(flash[:success]).to match(/Permanently deleted 2 pulses/)
    end

    it "shows error if no pulses selected" do
      delete :bulk_destroy, params: {pulse_ids: []}

      expect(flash[:error]).to include("No pulses selected")
    end

    it "handles singular vs plural flash message" do
      delete :bulk_destroy, params: {pulse_ids: [pulse1.id]}

      expect(flash[:success]).to match(/Permanently deleted 1 pulse\./)
    end

    it "redirects back" do
      delete :bulk_destroy, params: {pulse_ids: [pulse1.id]}

      expect(response).to redirect_to(admin_pulse_wire_index_path)
    end
  end
end
