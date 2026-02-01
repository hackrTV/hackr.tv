require "rails_helper"

RSpec.describe "Api::Admin::Uplink", type: :request do
  before { ENV["HACKR_ADMIN_API_TOKEN"] = admin_token }
  after { ENV.delete("HACKR_ADMIN_API_TOKEN") }

  let(:channel) { create(:chat_channel) }

  describe "POST /api/admin/uplink/send_packet" do
    context "with admin hackr" do
      let(:admin_hackr) { create(:grid_hackr, :admin) }

      it "creates a packet" do
        post "/api/admin/uplink/send_packet",
          params: {hackr_alias: admin_hackr.hackr_alias, channel_slug: channel.slug, content: "Hello"},
          headers: admin_headers

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body["packet"]["content"]).to eq("Hello")
      end

      it "bypasses squelch" do
        issuer = create(:grid_hackr, :admin)
        UserPunishment.squelch!(admin_hackr, issued_by: issuer)

        post "/api/admin/uplink/send_packet",
          params: {hackr_alias: admin_hackr.hackr_alias, channel_slug: channel.slug, content: "Bypassed"},
          headers: admin_headers

        expect(response).to have_http_status(:created)
      end

      it "bypasses blackout" do
        issuer = create(:grid_hackr, :admin)
        UserPunishment.blackout!(admin_hackr, issued_by: issuer)

        post "/api/admin/uplink/send_packet",
          params: {hackr_alias: admin_hackr.hackr_alias, channel_slug: channel.slug, content: "Bypassed"},
          headers: admin_headers

        expect(response).to have_http_status(:created)
      end

      it "bypasses slow mode" do
        slow_channel = create(:chat_channel, :slow_mode)
        create(:chat_message, chat_channel: slow_channel, grid_hackr: admin_hackr, created_at: 1.second.ago)

        post "/api/admin/uplink/send_packet",
          params: {hackr_alias: admin_hackr.hackr_alias, channel_slug: slow_channel.slug, content: "Fast"},
          headers: admin_headers

        expect(response).to have_http_status(:created)
      end

      it "bypasses channel accessibility for inactive channels" do
        inactive_channel = create(:chat_channel, :inactive)

        post "/api/admin/uplink/send_packet",
          params: {hackr_alias: admin_hackr.hackr_alias, channel_slug: inactive_channel.slug, content: "Bypassed"},
          headers: admin_headers

        expect(response).to have_http_status(:created)
      end

      it "bypasses channel accessibility for role-restricted channels" do
        # Even though admin_hackr would normally have access, this confirms the bypass path
        operator_channel = create(:chat_channel, :operator_only)

        post "/api/admin/uplink/send_packet",
          params: {hackr_alias: admin_hackr.hackr_alias, channel_slug: operator_channel.slug, content: "Bypassed"},
          headers: admin_headers

        expect(response).to have_http_status(:created)
      end
    end

    context "with non-admin hackr" do
      let(:operative) { create(:grid_hackr) }

      it "creates a packet when not punished" do
        post "/api/admin/uplink/send_packet",
          params: {hackr_alias: operative.hackr_alias, channel_slug: channel.slug, content: "Hello"},
          headers: admin_headers

        expect(response).to have_http_status(:created)
      end

      it "blocks squelched hackr" do
        issuer = create(:grid_hackr, :admin)
        UserPunishment.squelch!(operative, issued_by: issuer)

        post "/api/admin/uplink/send_packet",
          params: {hackr_alias: operative.hackr_alias, channel_slug: channel.slug, content: "Blocked"},
          headers: admin_headers

        expect(response).to have_http_status(:forbidden)
      end

      it "blocks blackouted hackr" do
        issuer = create(:grid_hackr, :admin)
        UserPunishment.blackout!(operative, issued_by: issuer)

        post "/api/admin/uplink/send_packet",
          params: {hackr_alias: operative.hackr_alias, channel_slug: channel.slug, content: "Blocked"},
          headers: admin_headers

        expect(response).to have_http_status(:forbidden)
      end

      it "enforces slow mode" do
        slow_channel = create(:chat_channel, :slow_mode)
        create(:chat_message, chat_channel: slow_channel, grid_hackr: operative, created_at: 1.second.ago)

        post "/api/admin/uplink/send_packet",
          params: {hackr_alias: operative.hackr_alias, channel_slug: slow_channel.slug, content: "Slow"},
          headers: admin_headers

        expect(response).to have_http_status(:too_many_requests)
      end

      it "blocks access to inactive channels" do
        inactive_channel = create(:chat_channel, :inactive)

        post "/api/admin/uplink/send_packet",
          params: {hackr_alias: operative.hackr_alias, channel_slug: inactive_channel.slug, content: "Blocked"},
          headers: admin_headers

        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)["error"]).to include("cannot access")
      end

      it "blocks access to role-restricted channels" do
        admin_channel = create(:chat_channel, :admin_only)

        post "/api/admin/uplink/send_packet",
          params: {hackr_alias: operative.hackr_alias, channel_slug: admin_channel.slug, content: "Blocked"},
          headers: admin_headers

        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)["error"]).to include("cannot access")
      end

      it "blocks access to livestream channels when no stream is live" do
        live_channel = create(:chat_channel, :livestream_only)

        post "/api/admin/uplink/send_packet",
          params: {hackr_alias: operative.hackr_alias, channel_slug: live_channel.slug, content: "Blocked"},
          headers: admin_headers

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "error cases" do
      let(:hackr) { create(:grid_hackr) }

      it "returns 404 for unknown channel" do
        post "/api/admin/uplink/send_packet",
          params: {hackr_alias: hackr.hackr_alias, channel_slug: "nonexistent", content: "Test"},
          headers: admin_headers

        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 for unknown hackr" do
        post "/api/admin/uplink/send_packet",
          params: {hackr_alias: "nonexistent_hackr", channel_slug: channel.slug, content: "Test"},
          headers: admin_headers

        expect(response).to have_http_status(:not_found)
      end

      it "applies profanity filter" do
        allow(Obscenity).to receive(:profane?).and_call_original
        allow(Obscenity).to receive(:profane?).with("bad").and_return(true)

        post "/api/admin/uplink/send_packet",
          params: {hackr_alias: hackr.hackr_alias, channel_slug: channel.slug, content: "bad"},
          headers: admin_headers

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "regression: regular API still enforces squelch/blackout" do
      let(:operative) { create(:grid_hackr) }

      it "regular uplink API blocks squelched user" do
        issuer = create(:grid_hackr, :admin)
        UserPunishment.squelch!(operative, issued_by: issuer)
        operative.generate_api_token!

        post "/api/uplink/channels/#{channel.slug}/packets",
          params: {packet: {content: "Should be blocked"}},
          headers: {"Authorization" => "Bearer #{operative.api_token}"}

        expect(response).to have_http_status(:forbidden)
      end

      it "regular uplink API blocks blackouted user" do
        issuer = create(:grid_hackr, :admin)
        UserPunishment.blackout!(operative, issued_by: issuer)
        operative.generate_api_token!

        post "/api/uplink/channels/#{channel.slug}/packets",
          params: {packet: {content: "Should be blocked"}},
          headers: {"Authorization" => "Bearer #{operative.api_token}"}

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
