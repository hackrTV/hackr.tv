require "rails_helper"

RSpec.describe Api::PulsesController, type: :controller do
  let(:hackr) { create(:grid_hackr) }
  let(:admin_hackr) { create(:grid_hackr, :admin) }
  let(:other_hackr) { create(:grid_hackr) }

  describe "GET #index" do
    context "without authentication" do
      it "returns active pulses (no auth required for reading)" do
        pulse1 = create(:pulse, grid_hackr: hackr)
        pulse2 = create(:pulse, grid_hackr: other_hackr)

        get :index, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["pulses"].length).to eq(2)
      end

      it "excludes signal-dropped pulses by default" do
        active_pulse = create(:pulse, grid_hackr: hackr)
        dropped_pulse = create(:pulse, :signal_dropped, grid_hackr: hackr)

        get :index, format: :json

        json = JSON.parse(response.body)
        pulse_ids = json["pulses"].map { |p| p["id"] }
        expect(pulse_ids).to include(active_pulse.id)
        expect(pulse_ids).not_to include(dropped_pulse.id)
      end

      it "orders pulses by pulsed_at descending" do
        pulse1 = create(:pulse, grid_hackr: hackr, pulsed_at: 2.days.ago)
        pulse2 = create(:pulse, grid_hackr: hackr, pulsed_at: 1.day.ago)
        pulse3 = create(:pulse, grid_hackr: hackr, pulsed_at: 3.days.ago)

        get :index, format: :json

        json = JSON.parse(response.body)
        expect(json["pulses"][0]["id"]).to eq(pulse2.id)
        expect(json["pulses"][1]["id"]).to eq(pulse1.id)
        expect(json["pulses"][2]["id"]).to eq(pulse3.id)
      end
    end

    context "with hackr filter" do
      it "filters pulses by hackr alias" do
        pulse1 = create(:pulse, grid_hackr: hackr)
        pulse2 = create(:pulse, grid_hackr: other_hackr)

        get :index, params: {hackr: hackr.hackr_alias}, format: :json

        json = JSON.parse(response.body)
        expect(json["pulses"].length).to eq(1)
        expect(json["pulses"][0]["id"]).to eq(pulse1.id)
      end

      it "is case-insensitive" do
        pulse = create(:pulse, grid_hackr: hackr)

        get :index, params: {hackr: hackr.hackr_alias.upcase}, format: :json

        json = JSON.parse(response.body)
        expect(json["pulses"].length).to eq(1)
        expect(json["pulses"][0]["id"]).to eq(pulse.id)
      end

      it "returns empty array for non-existent hackr" do
        get :index, params: {hackr: "NonExistent"}, format: :json

        json = JSON.parse(response.body)
        expect(json["pulses"]).to be_empty
        expect(json["meta"]["total"]).to eq(0)
      end
    end

    context "with status filter" do
      it "returns active pulses when filter=active" do
        active_pulse = create(:pulse, grid_hackr: hackr)
        dropped_pulse = create(:pulse, :signal_dropped, grid_hackr: hackr)

        get :index, params: {filter: "active"}, format: :json

        json = JSON.parse(response.body)
        pulse_ids = json["pulses"].map { |p| p["id"] }
        expect(pulse_ids).to include(active_pulse.id)
        expect(pulse_ids).not_to include(dropped_pulse.id)
      end

      it "returns dropped pulses when filter=dropped" do
        active_pulse = create(:pulse, grid_hackr: hackr)
        dropped_pulse = create(:pulse, :signal_dropped, grid_hackr: hackr)

        get :index, params: {filter: "dropped"}, format: :json

        json = JSON.parse(response.body)
        pulse_ids = json["pulses"].map { |p| p["id"] }
        expect(pulse_ids).not_to include(active_pulse.id)
        expect(pulse_ids).to include(dropped_pulse.id)
      end
    end

    context "with parent_pulse_id filter" do
      it "returns only splices for the given parent pulse" do
        parent_pulse = create(:pulse, grid_hackr: hackr)
        splice1 = create(:pulse, grid_hackr: other_hackr, parent_pulse: parent_pulse)
        splice2 = create(:pulse, grid_hackr: admin_hackr, parent_pulse: parent_pulse)
        unrelated_pulse = create(:pulse, grid_hackr: hackr)

        get :index, params: {parent_pulse_id: parent_pulse.id}, format: :json

        json = JSON.parse(response.body)
        pulse_ids = json["pulses"].map { |p| p["id"] }
        expect(pulse_ids).to include(splice1.id, splice2.id)
        expect(pulse_ids).not_to include(parent_pulse.id, unrelated_pulse.id)
      end
    end

    context "pagination" do
      it "paginates results" do
        create_list(:pulse, 120, grid_hackr: hackr)

        get :index, params: {page: 2, per_page: 60}, format: :json

        json = JSON.parse(response.body)
        expect(json["pulses"].length).to eq(60)
        expect(json["meta"]["page"]).to eq(2)
        expect(json["meta"]["per_page"]).to eq(60)
        expect(json["meta"]["total"]).to eq(120)
        expect(json["meta"]["total_pages"]).to eq(2)
      end

      it "defaults to per_page 50" do
        create_list(:pulse, 60, grid_hackr: hackr)

        get :index, format: :json

        json = JSON.parse(response.body)
        expect(json["pulses"].length).to eq(50)
        expect(json["meta"]["per_page"]).to eq(50)
      end

      it "caps per_page at 100" do
        get :index, params: {per_page: 500}, format: :json

        json = JSON.parse(response.body)
        expect(json["meta"]["per_page"]).to eq(100)
      end

      it "defaults to page 1" do
        get :index, format: :json

        json = JSON.parse(response.body)
        expect(json["meta"]["page"]).to eq(1)
      end
    end

    context "when authenticated" do
      before { session[:grid_hackr_id] = hackr.id }

      it "includes current_hackr info" do
        get :index, format: :json

        json = JSON.parse(response.body)
        expect(json["current_hackr"]["hackr_alias"]).to eq(hackr.hackr_alias)
        expect(json["current_hackr"]["role"]).to eq(hackr.role)
      end

      it "includes is_echoed_by_current_hackr flag" do
        pulse = create(:pulse, grid_hackr: other_hackr)
        create(:echo, pulse: pulse, grid_hackr: hackr)

        get :index, format: :json

        json = JSON.parse(response.body)
        expect(json["pulses"][0]["is_echoed_by_current_hackr"]).to be true
      end
    end
  end

  describe "GET #show" do
    let!(:pulse) { create(:pulse, grid_hackr: hackr) }

    it "returns the pulse" do
      get :show, params: {id: pulse.id}, format: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["pulse"]["id"]).to eq(pulse.id)
      expect(json["pulse"]["content"]).to eq(pulse.content)
    end

    it "includes the full thread" do
      splice1 = create(:pulse, grid_hackr: other_hackr, parent_pulse: pulse)
      splice2 = create(:pulse, grid_hackr: admin_hackr, parent_pulse: splice1)

      get :show, params: {id: pulse.id}, format: :json

      json = JSON.parse(response.body)
      thread_ids = json["thread"].map { |p| p["id"] }
      expect(thread_ids).to include(pulse.id, splice1.id, splice2.id)
    end

    it "returns 404 for non-existent pulse" do
      get :show, params: {id: 99999}, format: :json

      expect(response).to have_http_status(:not_found)
      json = JSON.parse(response.body)
      expect(json["error"]).to include("not found")
    end
  end

  describe "POST #create" do
    context "when authenticated" do
      before { session[:grid_hackr_id] = hackr.id }

      it "creates a new pulse" do
        expect {
          post :create, params: {pulse: {content: "Test pulse"}}, format: :json
        }.to change(Pulse, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["pulse"]["content"]).to eq("Test pulse")
      end

      it "creates a splice when parent_pulse_id provided" do
        parent = create(:pulse, grid_hackr: other_hackr)

        post :create, params: {pulse: {content: "Reply", parent_pulse_id: parent.id}}, format: :json

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["pulse"]["parent_pulse_id"]).to eq(parent.id)
        expect(json["pulse"]["is_splice"]).to be true
      end

      it "returns error for content exceeding 256 characters" do
        long_content = "a" * 257

        post :create, params: {pulse: {content: long_content}}, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["error"]).to include("too long")
      end

      it "returns error for blank content" do
        post :create, params: {pulse: {content: ""}}, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["error"]).to include("can't be blank")
      end
    end

    context "when not authenticated" do
      it "returns 401 unauthorized" do
        post :create, params: {pulse: {content: "Test"}}, format: :json

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("Authentication required")
      end
    end
  end

  describe "DELETE #destroy" do
    context "when authenticated as pulse owner" do
      before { session[:grid_hackr_id] = hackr.id }

      let!(:pulse) { create(:pulse, grid_hackr: hackr) }

      it "deletes the pulse" do
        expect {
          delete :destroy, params: {id: pulse.id}, format: :json
        }.to change(Pulse, :count).by(-1)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
      end

      it "cascades to echoes" do
        create(:echo, pulse: pulse, grid_hackr: other_hackr)

        expect {
          delete :destroy, params: {id: pulse.id}, format: :json
        }.to change(Echo, :count).by(-1)
      end

      it "cascades to splices" do
        create(:pulse, parent_pulse: pulse, grid_hackr: other_hackr)

        expect {
          delete :destroy, params: {id: pulse.id}, format: :json
        }.to change(Pulse, :count).by(-2) # parent + splice
      end
    end

    context "when authenticated but not pulse owner" do
      before { session[:grid_hackr_id] = other_hackr.id }

      let!(:pulse) { create(:pulse, grid_hackr: hackr) }

      it "returns 403 forbidden" do
        delete :destroy, params: {id: pulse.id}, format: :json

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("not authorized")
      end

      it "does not delete the pulse" do
        expect {
          delete :destroy, params: {id: pulse.id}, format: :json
        }.not_to change(Pulse, :count)
      end
    end

    context "when not authenticated" do
      let!(:pulse) { create(:pulse, grid_hackr: hackr) }

      it "returns 401 unauthorized" do
        delete :destroy, params: {id: pulse.id}, format: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST #signal_drop" do
    context "when authenticated as admin" do
      before { session[:grid_hackr_id] = admin_hackr.id }

      let!(:pulse) { create(:pulse, grid_hackr: hackr) }

      it "marks pulse as signal-dropped" do
        expect {
          post :signal_drop, params: {id: pulse.id}, format: :json
          pulse.reload
        }.to change { pulse.signal_dropped }.from(false).to(true)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["message"]).to include("signal-dropped")
      end

      it "sets signal_dropped_at timestamp" do
        post :signal_drop, params: {id: pulse.id}, format: :json
        pulse.reload

        expect(pulse.signal_dropped_at).to be_present
      end
    end

    context "when authenticated as non-admin" do
      before { session[:grid_hackr_id] = hackr.id }

      let!(:pulse) { create(:pulse, grid_hackr: other_hackr) }

      it "returns 403 forbidden" do
        post :signal_drop, params: {id: pulse.id}, format: :json

        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("Admin access required")
      end

      it "does not signal-drop the pulse" do
        expect {
          post :signal_drop, params: {id: pulse.id}, format: :json
          pulse.reload
        }.not_to change { pulse.signal_dropped }
      end
    end

    context "when not authenticated" do
      let!(:pulse) { create(:pulse, grid_hackr: hackr) }

      it "returns 401 unauthorized" do
        post :signal_drop, params: {id: pulse.id}, format: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
