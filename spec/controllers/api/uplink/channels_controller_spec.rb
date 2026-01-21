require "rails_helper"

RSpec.describe Api::Uplink::ChannelsController, type: :controller do
  let(:hackr) { create(:grid_hackr) }
  let(:operator) { create(:grid_hackr, :operator) }
  let(:admin) { create(:grid_hackr, :admin) }

  let!(:ambient_channel) { create(:chat_channel, slug: "ambient", name: "#ambient") }
  let!(:live_channel) { create(:chat_channel, :livestream_only, slug: "live", name: "#live") }
  let!(:operator_channel) { create(:chat_channel, :operator_only, slug: "ops", name: "#ops") }
  let!(:inactive_channel) { create(:chat_channel, :inactive, slug: "inactive", name: "#inactive") }

  describe "GET #index" do
    context "when authenticated" do
      before { session[:grid_hackr_id] = hackr.id }

      it "returns active channels" do
        get :index, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        slugs = json["channels"].map { |c| c["slug"] }

        expect(slugs).to include("ambient", "live", "ops")
        expect(slugs).not_to include("inactive")
      end

      it "includes channel metadata" do
        get :index, format: :json

        json = JSON.parse(response.body)
        channel = json["channels"].find { |c| c["slug"] == "ambient" }

        expect(channel["name"]).to eq("#ambient")
        expect(channel["requires_livestream"]).to be false
        expect(channel).to have_key("accessible")
        expect(channel).to have_key("currently_available")
      end

      it "indicates accessibility based on role" do
        get :index, format: :json

        json = JSON.parse(response.body)
        ops_channel = json["channels"].find { |c| c["slug"] == "ops" }

        expect(ops_channel["accessible"]).to be false
      end

      it "includes current_hackr info" do
        get :index, format: :json

        json = JSON.parse(response.body)
        expect(json["current_hackr"]["hackr_alias"]).to eq(hackr.hackr_alias)
      end
    end

    context "when authenticated as operator" do
      before { session[:grid_hackr_id] = operator.id }

      it "shows operator channel as accessible" do
        get :index, format: :json

        json = JSON.parse(response.body)
        ops_channel = json["channels"].find { |c| c["slug"] == "ops" }

        expect(ops_channel["accessible"]).to be true
      end
    end

    context "when not authenticated" do
      it "returns channels but current_hackr is nil" do
        get :index, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["channels"]).to be_present
        expect(json["current_hackr"]).to be_nil
      end
    end
  end

  describe "GET #show" do
    context "when authenticated" do
      before { session[:grid_hackr_id] = hackr.id }

      it "returns channel details" do
        get :show, params: {slug: "ambient"}, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["channel"]["slug"]).to eq("ambient")
        expect(json["channel"]["name"]).to eq("#ambient")
      end

      it "returns 404 for non-existent channel" do
        get :show, params: {slug: "nonexistent"}, format: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
