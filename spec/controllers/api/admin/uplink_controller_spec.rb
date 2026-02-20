require "rails_helper"

RSpec.describe Api::Admin::UplinkController, type: :controller do
  let!(:admin_hackr) { create(:grid_hackr, :admin) }
  let!(:raw_token) { admin_hackr.generate_api_token! }

  before do
    request.headers["Authorization"] = "Bearer #{admin_hackr.hackr_alias}:#{raw_token}"
  end

  let(:channel) { create(:chat_channel) }

  describe "POST #send_packet" do
    it "creates a chat message" do
      post :send_packet, params: {
        channel_slug: channel.slug,
        content: "Admin message"
      }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["packet"]["content"]).to eq("Admin message")
      expect(body["packet"]["grid_hackr"]["hackr_alias"]).to eq(admin_hackr.hackr_alias)
    end

    it "bypasses squelch for admin" do
      issuer = create(:grid_hackr, :admin)
      UserPunishment.squelch!(admin_hackr, issued_by: issuer, reason: "test")

      post :send_packet, params: {
        channel_slug: channel.slug,
        content: "Admin bypasses squelch"
      }

      expect(response).to have_http_status(:created)
    end

    it "bypasses blackout for admin" do
      issuer = create(:grid_hackr, :admin)
      UserPunishment.blackout!(admin_hackr, issued_by: issuer, reason: "test")

      post :send_packet, params: {
        channel_slug: channel.slug,
        content: "Admin bypasses blackout"
      }

      expect(response).to have_http_status(:created)
    end

    it "bypasses slow mode for admin" do
      slow_channel = create(:chat_channel, :slow_mode)
      create(:chat_message, chat_channel: slow_channel, grid_hackr: admin_hackr, created_at: 1.second.ago)

      post :send_packet, params: {
        channel_slug: slow_channel.slug,
        content: "Admin bypasses slow mode"
      }

      expect(response).to have_http_status(:created)
    end

    context "error cases" do
      it "returns 404 for unknown channel" do
        post :send_packet, params: {
          channel_slug: "nonexistent",
          content: "Test"
        }

        expect(response).to have_http_status(:not_found)
      end

      it "applies profanity filter" do
        allow(Obscenity).to receive(:profane?).and_call_original
        allow(Obscenity).to receive(:profane?).with("bad content").and_return(true)

        post :send_packet, params: {
          channel_slug: channel.slug,
          content: "bad content"
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with livestream channel" do
      let(:live_channel) { create(:chat_channel, :livestream_only) }

      it "links hackr_stream when channel requires livestream" do
        artist = create(:artist)
        stream = create(:hackr_stream, :live, artist: artist)

        post :send_packet, params: {
          channel_slug: live_channel.slug,
          content: "Chat during stream"
        }

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["packet"]["hackr_stream_id"]).to eq(stream.id)
      end
    end
  end
end
