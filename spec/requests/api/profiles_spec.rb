require "rails_helper"

RSpec.describe "Api::Profiles", type: :request do
  # Stored alias is mixed-case; URLs reach the controller lowercased (the
  # LowercaseRedirect Rack middleware canonicalizes paths), so requesting
  # the lowercase form also exercises the case-insensitive lookup.
  let(:hackr) { create(:grid_hackr, hackr_alias: "GhostWire", bio: "Just a ghost in the wire.") }

  before { Rails.cache.clear }

  def login_as(h)
    post "/api/grid/login", params: {hackr_alias: h.hackr_alias, password: "hackthegrid"}, as: :json
  end

  describe "GET /api/profiles/:alias" do
    it "returns the public profile (case-insensitive alias) with stats and pinned pulses" do
      create_list(:pulse, 2, grid_hackr: hackr)
      pinned = create(:pulse, grid_hackr: hackr)
      PulsePin.create!(grid_hackr: hackr, pulse: pinned)

      get "/api/profiles/ghostwire"

      expect(response).to have_http_status(:ok)
      profile = response.parsed_body["profile"]
      expect(profile["hackr_alias"]).to eq("GhostWire")
      expect(profile["bio"]).to eq("Just a ghost in the wire.")
      expect(profile["stats"]["pulses"]).to eq(3)
      expect(profile["pinned_pulses"].map { |p| p["id"] }).to eq([pinned.id])
      expect(response.parsed_body["is_self"]).to be false
    end

    it "404s for an unknown alias" do
      get "/api/profiles/nobody_here"
      expect(response).to have_http_status(:not_found)
    end

    it "omits signal-dropped pulses from the pinned set" do
      dropped = create(:pulse, grid_hackr: hackr)
      PulsePin.create!(grid_hackr: hackr, pulse: dropped)
      dropped.signal_drop!

      get "/api/profiles/ghostwire"

      expect(response.parsed_body["profile"]["pinned_pulses"]).to be_empty
    end

    it "marks is_self when the viewer owns the profile" do
      login_as(hackr)
      get "/api/profiles/ghostwire"
      expect(response.parsed_body["is_self"]).to be true
    end

    it "sums watch_seconds across the hackr's sessions" do
      HackrWatchSession.create!(grid_hackr: hackr, connected_at: Time.current,
        last_heartbeat_at: Time.current, accumulated_seconds: 180, disconnected_at: Time.current)
      get "/api/profiles/ghostwire"
      expect(response.parsed_body["profile"]["stats"]["watch_seconds"]).to eq(180)
    end

    it "coarsens last_active_at to a 5-minute boundary" do
      ts = Time.zone.parse("2026-06-15 12:03:47")
      hackr.update_column(:last_activity_at, ts)
      get "/api/profiles/ghostwire"
      coarse = Time.zone.parse(response.parsed_body["profile"]["last_active_at"])
      expect(coarse.to_i % 300).to eq(0)
      expect(coarse).to eq(Time.zone.at((ts.to_i / 300) * 300))
    end
  end
end
