require "rails_helper"

RSpec.describe Api::EchoesController, type: :controller do
  let(:hackr) { create(:grid_hackr) }
  let(:other_hackr) { create(:grid_hackr) }
  let(:pulse) { create(:pulse, grid_hackr: other_hackr) }

  describe "POST #create (toggle echo)" do
    context "when authenticated" do
      before { session[:grid_hackr_id] = hackr.id }

      context "when echo does not exist" do
        it "creates a new echo" do
          expect {
            post :create, params: {pulse_id: pulse.id}, format: :json
          }.to change(Echo, :count).by(1)

          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json["success"]).to be true
          expect(json["echoed"]).to be true
          expect(json["message"]).to include("echoed")
        end

        it "increments echo_count" do
          expect {
            post :create, params: {pulse_id: pulse.id}, format: :json
            pulse.reload
          }.to change { pulse.echo_count }.by(1)
        end

        it "returns updated echo_count in response" do
          post :create, params: {pulse_id: pulse.id}, format: :json

          json = JSON.parse(response.body)
          expect(json["echo_count"]).to eq(1)
        end

        it "associates echo with current hackr" do
          post :create, params: {pulse_id: pulse.id}, format: :json

          echo = Echo.last
          expect(echo.grid_hackr).to eq(hackr)
          expect(echo.pulse).to eq(pulse)
        end

        it "sets echoed_at timestamp" do
          post :create, params: {pulse_id: pulse.id}, format: :json

          echo = Echo.last
          expect(echo.echoed_at).to be_present
          expect(echo.echoed_at).to be_within(1.second).of(Time.current)
        end
      end

      context "when echo already exists (un-echo)" do
        let!(:existing_echo) { create(:echo, pulse: pulse, grid_hackr: hackr) }

        it "destroys the existing echo" do
          expect {
            post :create, params: {pulse_id: pulse.id}, format: :json
          }.to change(Echo, :count).by(-1)

          expect(response).to have_http_status(:success)
          json = JSON.parse(response.body)
          expect(json["success"]).to be true
          expect(json["echoed"]).to be false
          expect(json["message"]).to include("removed")
        end

        it "decrements echo_count" do
          expect {
            post :create, params: {pulse_id: pulse.id}, format: :json
            pulse.reload
          }.to change { pulse.echo_count }.by(-1)
        end

        it "returns updated echo_count in response" do
          post :create, params: {pulse_id: pulse.id}, format: :json

          json = JSON.parse(response.body)
          expect(json["echo_count"]).to eq(0)
        end
      end

      context "when pulse does not exist" do
        it "returns 404 not found" do
          post :create, params: {pulse_id: 99999}, format: :json

          expect(response).to have_http_status(:not_found)
          json = JSON.parse(response.body)
          expect(json["error"]).to include("not found")
        end
      end

      context "when echoing own pulse" do
        let(:own_pulse) { create(:pulse, grid_hackr: hackr) }

        it "allows echoing own pulse" do
          expect {
            post :create, params: {pulse_id: own_pulse.id}, format: :json
          }.to change(Echo, :count).by(1)

          expect(response).to have_http_status(:created)
        end
      end
    end

    context "when not authenticated" do
      it "returns 401 unauthorized" do
        post :create, params: {pulse_id: pulse.id}, format: :json

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("Authentication required")
      end

      it "does not create an echo" do
        expect {
          post :create, params: {pulse_id: pulse.id}, format: :json
        }.not_to change(Echo, :count)
      end
    end
  end

  describe "GET #index" do
    context "when authenticated" do
      before { session[:grid_hackr_id] = hackr.id }

      it "returns list of hackrs who echoed the pulse" do
        echo1 = create(:echo, pulse: pulse, grid_hackr: hackr)
        echo2 = create(:echo, pulse: pulse, grid_hackr: other_hackr)

        get :index, params: {pulse_id: pulse.id}, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["pulse_id"]).to eq(pulse.id)
        expect(json["echo_count"]).to eq(2)
        expect(json["echoes"].length).to eq(2)
      end

      it "includes hackr details in echo data" do
        echo = create(:echo, pulse: pulse, grid_hackr: hackr)

        get :index, params: {pulse_id: pulse.id}, format: :json

        json = JSON.parse(response.body)
        echo_data = json["echoes"][0]
        expect(echo_data["id"]).to eq(echo.id)
        expect(echo_data["hackr"]["hackr_alias"]).to eq(hackr.hackr_alias)
        expect(echo_data["hackr"]["role"]).to eq(hackr.role)
      end

      it "includes echoed_at timestamp" do
        echo = create(:echo, pulse: pulse, grid_hackr: hackr)

        get :index, params: {pulse_id: pulse.id}, format: :json

        json = JSON.parse(response.body)
        expect(json["echoes"][0]["echoed_at"]).to be_present
      end

      it "orders echoes by echoed_at descending (most recent first)" do
        echo1 = create(:echo, pulse: pulse, grid_hackr: hackr, echoed_at: 2.days.ago)
        echo2 = create(:echo, pulse: pulse, grid_hackr: other_hackr, echoed_at: 1.day.ago)

        get :index, params: {pulse_id: pulse.id}, format: :json

        json = JSON.parse(response.body)
        expect(json["echoes"][0]["id"]).to eq(echo2.id)
        expect(json["echoes"][1]["id"]).to eq(echo1.id)
      end

      it "returns empty array when pulse has no echoes" do
        get :index, params: {pulse_id: pulse.id}, format: :json

        json = JSON.parse(response.body)
        expect(json["echoes"]).to be_empty
        expect(json["echo_count"]).to eq(0)
      end

      it "returns 404 for non-existent pulse" do
        get :index, params: {pulse_id: 99999}, format: :json

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("not found")
      end
    end

    context "when not authenticated" do
      it "returns 401 unauthorized" do
        get :index, params: {pulse_id: pulse.id}, format: :json

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("Authentication required")
      end
    end
  end
end
