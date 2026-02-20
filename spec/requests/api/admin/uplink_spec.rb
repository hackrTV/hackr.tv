require "rails_helper"

RSpec.describe "Api::Admin::Uplink", type: :request do
  let!(:admin_hackr) { create(:grid_hackr, :admin) }
  let!(:raw_token) { admin_hackr.generate_api_token! }
  let(:valid_headers) { admin_headers_for(admin_hackr, raw_token) }

  let(:channel) { create(:chat_channel) }

  describe "POST /api/admin/uplink/send_packet" do
    it "creates a packet" do
      post "/api/admin/uplink/send_packet",
        params: {channel_slug: channel.slug, content: "Hello"},
        headers: valid_headers

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["packet"]["content"]).to eq("Hello")
    end

    it "bypasses squelch" do
      issuer = create(:grid_hackr, :admin)
      UserPunishment.squelch!(admin_hackr, issued_by: issuer)

      post "/api/admin/uplink/send_packet",
        params: {channel_slug: channel.slug, content: "Bypassed"},
        headers: valid_headers

      expect(response).to have_http_status(:created)
    end

    it "bypasses blackout" do
      issuer = create(:grid_hackr, :admin)
      UserPunishment.blackout!(admin_hackr, issued_by: issuer)

      post "/api/admin/uplink/send_packet",
        params: {channel_slug: channel.slug, content: "Bypassed"},
        headers: valid_headers

      expect(response).to have_http_status(:created)
    end

    it "bypasses slow mode" do
      slow_channel = create(:chat_channel, :slow_mode)
      create(:chat_message, chat_channel: slow_channel, grid_hackr: admin_hackr, created_at: 1.second.ago)

      post "/api/admin/uplink/send_packet",
        params: {channel_slug: slow_channel.slug, content: "Fast"},
        headers: valid_headers

      expect(response).to have_http_status(:created)
    end

    it "bypasses channel accessibility for inactive channels" do
      inactive_channel = create(:chat_channel, :inactive)

      post "/api/admin/uplink/send_packet",
        params: {channel_slug: inactive_channel.slug, content: "Bypassed"},
        headers: valid_headers

      expect(response).to have_http_status(:created)
    end

    it "bypasses channel accessibility for role-restricted channels" do
      operator_channel = create(:chat_channel, :operator_only)

      post "/api/admin/uplink/send_packet",
        params: {channel_slug: operator_channel.slug, content: "Bypassed"},
        headers: valid_headers

      expect(response).to have_http_status(:created)
    end

    context "error cases" do
      it "returns 404 for unknown channel" do
        post "/api/admin/uplink/send_packet",
          params: {channel_slug: "nonexistent", content: "Test"},
          headers: valid_headers

        expect(response).to have_http_status(:not_found)
      end

      it "applies profanity filter" do
        allow(Obscenity).to receive(:profane?).and_call_original
        allow(Obscenity).to receive(:profane?).with("bad").and_return(true)

        post "/api/admin/uplink/send_packet",
          params: {channel_slug: channel.slug, content: "bad"},
          headers: valid_headers

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "regression: regular API still enforces squelch/blackout" do
      let(:operative) { create(:grid_hackr) }

      it "regular uplink API blocks squelched user" do
        issuer = create(:grid_hackr, :admin)
        UserPunishment.squelch!(operative, issued_by: issuer)
        operative_token = operative.generate_api_token!

        post "/api/uplink/channels/#{channel.slug}/packets",
          params: {packet: {content: "Should be blocked"}},
          headers: {"Authorization" => "Bearer #{operative.hackr_alias}:#{operative_token}"}

        expect(response).to have_http_status(:forbidden)
      end

      it "regular uplink API blocks blackedout user" do
        issuer = create(:grid_hackr, :admin)
        UserPunishment.blackout!(operative, issued_by: issuer)
        operative_token = operative.generate_api_token!

        post "/api/uplink/channels/#{channel.slug}/packets",
          params: {packet: {content: "Should be blocked"}},
          headers: {"Authorization" => "Bearer #{operative.hackr_alias}:#{operative_token}"}

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
