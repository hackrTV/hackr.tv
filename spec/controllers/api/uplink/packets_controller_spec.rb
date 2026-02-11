require "rails_helper"

RSpec.describe Api::Uplink::PacketsController, type: :controller do
  let(:hackr) { create(:grid_hackr) }
  let(:operator) { create(:grid_hackr, :operator) }
  let(:admin) { create(:grid_hackr, :admin) }
  let(:channel) { create(:chat_channel, slug: "ambient") }

  describe "GET #index" do
    context "when authenticated" do
      before { session[:grid_hackr_id] = hackr.id }

      it "returns recent packets for the channel" do
        create(:chat_message, chat_channel: channel, grid_hackr: hackr)
        create(:chat_message, chat_channel: channel, grid_hackr: hackr)

        get :index, params: {channel_slug: channel.slug}, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["packets"].length).to eq(2)
      end

      it "excludes dropped packets" do
        active = create(:chat_message, chat_channel: channel, grid_hackr: hackr)
        create(:chat_message, :dropped, chat_channel: channel, grid_hackr: hackr)

        get :index, params: {channel_slug: channel.slug}, format: :json

        json = JSON.parse(response.body)
        packet_ids = json["packets"].map { |p| p["id"] }
        expect(packet_ids).to contain_exactly(active.id)
      end

      it "returns 404 for non-existent channel" do
        get :index, params: {channel_slug: "nonexistent"}, format: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when not authenticated" do
      it "still returns packets (reading is public)" do
        create(:chat_message, chat_channel: channel, grid_hackr: hackr)

        get :index, params: {channel_slug: channel.slug}, format: :json

        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "POST #create" do
    context "when authenticated" do
      before { session[:grid_hackr_id] = hackr.id }

      it "creates a new packet" do
        expect {
          post :create, params: {channel_slug: channel.slug, packet: {content: "Hello world"}}, format: :json
        }.to change(ChatMessage, :count).by(1)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["packet"]["content"]).to eq("Hello world")
      end

      it "returns error for blank content" do
        post :create, params: {channel_slug: channel.slug, packet: {content: ""}}, format: :json

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
      end

      it "returns error for content exceeding 512 characters" do
        long_content = "a" * 513

        post :create, params: {channel_slug: channel.slug, packet: {content: long_content}}, format: :json

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["success"]).to be false
        expect(json["error"]).to include("too long")
      end

      context "when user is squelched" do
        before do
          create(:user_punishment, :squelch, grid_hackr: hackr)
        end

        it "returns error" do
          post :create, params: {channel_slug: channel.slug, packet: {content: "Test"}}, format: :json

          expect(response).to have_http_status(:forbidden)
          json = JSON.parse(response.body)
          expect(json["error"]).to include("squelched")
        end
      end

      context "when user is blackedout" do
        before do
          create(:user_punishment, :blackout, grid_hackr: hackr)
        end

        it "returns error" do
          post :create, params: {channel_slug: channel.slug, packet: {content: "Test"}}, format: :json

          expect(response).to have_http_status(:forbidden)
          json = JSON.parse(response.body)
          expect(json["error"]).to include("blackedout")
        end
      end

      context "with slow mode" do
        let(:slow_channel) { create(:chat_channel, :slow_mode, slow_mode_seconds: 30) }

        it "enforces slow mode cooldown" do
          create(:chat_message, chat_channel: slow_channel, grid_hackr: hackr, created_at: 10.seconds.ago)

          post :create, params: {channel_slug: slow_channel.slug, packet: {content: "Too fast"}}, format: :json

          expect(response).to have_http_status(:too_many_requests)
          json = JSON.parse(response.body)
          expect(json["wait_seconds"]).to be_present
        end

        it "allows sending after cooldown expires" do
          create(:chat_message, chat_channel: slow_channel, grid_hackr: hackr, created_at: 35.seconds.ago)

          post :create, params: {channel_slug: slow_channel.slug, packet: {content: "After cooldown"}}, format: :json

          expect(response).to have_http_status(:success)
        end
      end
    end

    context "when not authenticated" do
      it "returns 401 unauthorized" do
        post :create, params: {channel_slug: channel.slug, packet: {content: "Test"}}, format: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:packet) { create(:chat_message, chat_channel: channel, grid_hackr: hackr) }

    context "when authenticated as operator" do
      before { session[:grid_hackr_id] = operator.id }

      it "drops the packet" do
        delete :destroy, params: {id: packet.id}, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true

        packet.reload
        expect(packet.dropped).to be true
      end

      it "creates a moderation log entry" do
        expect {
          delete :destroy, params: {id: packet.id}, format: :json
        }.to change(ModerationLog, :count).by(1)
      end
    end

    context "when authenticated as regular user (not owner)" do
      let(:other_hackr) { create(:grid_hackr) }
      before { session[:grid_hackr_id] = other_hackr.id }

      it "returns 403 forbidden" do
        delete :destroy, params: {id: packet.id}, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when authenticated as packet owner" do
      before { session[:grid_hackr_id] = hackr.id }

      it "allows dropping own packet" do
        delete :destroy, params: {id: packet.id}, format: :json

        expect(response).to have_http_status(:success)
        packet.reload
        expect(packet.dropped).to be true
      end
    end

    context "when not authenticated" do
      it "returns 401 unauthorized" do
        delete :destroy, params: {id: packet.id}, format: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
