require "rails_helper"

RSpec.describe Api::Admin::UplinkController, type: :controller do
  before do
    ENV["HACKR_ADMIN_API_TOKEN"] = admin_token
    request.headers["Authorization"] = "Bearer #{admin_token}"
  end

  after { ENV.delete("HACKR_ADMIN_API_TOKEN") }

  let(:channel) { create(:chat_channel) }

  describe "POST #send_packet" do
    context "with admin hackr" do
      let(:admin_hackr) { create(:grid_hackr, :admin) }

      it "creates a chat message" do
        post :send_packet, params: {
          hackr_alias: admin_hackr.hackr_alias,
          channel_slug: channel.slug,
          content: "Admin message"
        }

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["packet"]["content"]).to eq("Admin message")
        expect(body["packet"]["grid_hackr"]["hackr_alias"]).to eq(admin_hackr.hackr_alias)
      end

      it "bypasses squelch for admin hackr" do
        issuer = create(:grid_hackr, :admin)
        UserPunishment.squelch!(admin_hackr, issued_by: issuer, reason: "test")

        post :send_packet, params: {
          hackr_alias: admin_hackr.hackr_alias,
          channel_slug: channel.slug,
          content: "Admin bypasses squelch"
        }

        expect(response).to have_http_status(:created)
      end

      it "bypasses blackout for admin hackr" do
        issuer = create(:grid_hackr, :admin)
        UserPunishment.blackout!(admin_hackr, issued_by: issuer, reason: "test")

        post :send_packet, params: {
          hackr_alias: admin_hackr.hackr_alias,
          channel_slug: channel.slug,
          content: "Admin bypasses blackout"
        }

        expect(response).to have_http_status(:created)
      end

      it "bypasses slow mode for admin hackr" do
        slow_channel = create(:chat_channel, :slow_mode)
        create(:chat_message, chat_channel: slow_channel, grid_hackr: admin_hackr, created_at: 1.second.ago)

        post :send_packet, params: {
          hackr_alias: admin_hackr.hackr_alias,
          channel_slug: slow_channel.slug,
          content: "Admin bypasses slow mode"
        }

        expect(response).to have_http_status(:created)
      end
    end

    context "with non-admin hackr" do
      let(:operative) { create(:grid_hackr) }

      it "creates a chat message when not punished" do
        post :send_packet, params: {
          hackr_alias: operative.hackr_alias,
          channel_slug: channel.slug,
          content: "Normal message"
        }

        expect(response).to have_http_status(:created)
      end

      it "blocks squelched non-admin hackr" do
        issuer = create(:grid_hackr, :admin)
        UserPunishment.squelch!(operative, issued_by: issuer, reason: "test")

        post :send_packet, params: {
          hackr_alias: operative.hackr_alias,
          channel_slug: channel.slug,
          content: "Should be blocked"
        }

        expect(response).to have_http_status(:forbidden)
        body = JSON.parse(response.body)
        expect(body["error"]).to include("squelched")
      end

      it "blocks blackedout non-admin hackr" do
        issuer = create(:grid_hackr, :admin)
        UserPunishment.blackout!(operative, issued_by: issuer, reason: "test")

        post :send_packet, params: {
          hackr_alias: operative.hackr_alias,
          channel_slug: channel.slug,
          content: "Should be blocked"
        }

        expect(response).to have_http_status(:forbidden)
        body = JSON.parse(response.body)
        expect(body["error"]).to include("blackedout")
      end

      it "enforces slow mode for non-admin hackr" do
        slow_channel = create(:chat_channel, :slow_mode)
        create(:chat_message, chat_channel: slow_channel, grid_hackr: operative, created_at: 1.second.ago)

        post :send_packet, params: {
          hackr_alias: operative.hackr_alias,
          channel_slug: slow_channel.slug,
          content: "Should be rate limited"
        }

        expect(response).to have_http_status(:too_many_requests)
      end
    end

    context "error cases" do
      let(:hackr) { create(:grid_hackr) }

      it "returns 404 for unknown channel" do
        post :send_packet, params: {
          hackr_alias: hackr.hackr_alias,
          channel_slug: "nonexistent",
          content: "Test"
        }

        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for unknown hackr" do
        post :send_packet, params: {
          hackr_alias: "nonexistent_hackr",
          channel_slug: channel.slug,
          content: "Test"
        }

        expect(response).to have_http_status(:not_found)
      end

      it "applies profanity filter" do
        allow(Obscenity).to receive(:profane?).and_call_original
        allow(Obscenity).to receive(:profane?).with("bad content").and_return(true)

        post :send_packet, params: {
          hackr_alias: hackr.hackr_alias,
          channel_slug: channel.slug,
          content: "bad content"
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with livestream channel" do
      let(:hackr) { create(:grid_hackr) }
      let(:live_channel) { create(:chat_channel, :livestream_only) }

      it "links hackr_stream when channel requires livestream" do
        artist = create(:artist)
        stream = create(:hackr_stream, :live, artist: artist)

        post :send_packet, params: {
          hackr_alias: hackr.hackr_alias,
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
