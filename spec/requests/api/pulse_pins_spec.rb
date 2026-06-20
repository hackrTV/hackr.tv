require "rails_helper"

RSpec.describe "Api::PulsePins", type: :request do
  let(:hackr) { create(:grid_hackr) }
  let(:pulse) { create(:pulse, grid_hackr: hackr) }

  def login_as(h)
    post "/api/grid/login", params: {hackr_alias: h.hackr_alias, password: "hackthegrid"}, as: :json
  end

  describe "POST /api/pulses/:pulse_id/pin" do
    it "requires login" do
      post "/api/pulses/#{pulse.id}/pin"
      expect(response).to have_http_status(:unauthorized)
    end

    it "pins an own pulse and returns the pinned set" do
      login_as(hackr)
      post "/api/pulses/#{pulse.id}/pin"
      expect(response).to have_http_status(:created)
      expect(response.parsed_body["pinned_pulses"].map { |p| p["id"] }).to eq([pulse.id])
      expect(hackr.pulse_pins.count).to eq(1)
    end

    it "refuses to pin another hackr's pulse" do
      login_as(hackr)
      post "/api/pulses/#{create(:pulse).id}/pin"
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "enforces the pin cap" do
      login_as(hackr)
      PulsePin::MAX_PINS.times { post "/api/pulses/#{create(:pulse, grid_hackr: hackr).id}/pin" }
      post "/api/pulses/#{pulse.id}/pin"
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to match(/at most/)
    end
  end

  describe "DELETE /api/pulses/:pulse_id/pin" do
    it "unpins the pulse" do
      login_as(hackr)
      post "/api/pulses/#{pulse.id}/pin"
      delete "/api/pulses/#{pulse.id}/pin"
      expect(response).to have_http_status(:ok)
      expect(hackr.pulse_pins.count).to eq(0)
    end

    it "resequences remaining pins to 0..n-1 after a middle delete" do
      login_as(hackr)
      a = create(:pulse, grid_hackr: hackr)
      b = create(:pulse, grid_hackr: hackr)
      c = create(:pulse, grid_hackr: hackr)
      post "/api/pulses/#{a.id}/pin"
      post "/api/pulses/#{b.id}/pin"
      post "/api/pulses/#{c.id}/pin"

      delete "/api/pulses/#{b.id}/pin"

      expect(hackr.pulse_pins.ordered.pluck(:position)).to eq([0, 1])
      expect(hackr.pinned_pulses.to_a).to eq([a, c])
    end
  end

  describe "PATCH /api/profile/pins" do
    it "reorders pins by the given pulse_ids" do
      login_as(hackr)
      a = create(:pulse, grid_hackr: hackr)
      b = create(:pulse, grid_hackr: hackr)
      post "/api/pulses/#{a.id}/pin"
      post "/api/pulses/#{b.id}/pin"

      patch "/api/profile/pins", params: {pulse_ids: [b.id, a.id]}, as: :json

      expect(response).to have_http_status(:ok)
      expect(hackr.pinned_pulses.to_a).to eq([b, a])
    end

    it "ignores duplicate/foreign ids, appends omitted, and resequences 0..n-1" do
      login_as(hackr)
      a = create(:pulse, grid_hackr: hackr)
      b = create(:pulse, grid_hackr: hackr)
      post "/api/pulses/#{a.id}/pin"
      post "/api/pulses/#{b.id}/pin"

      # b twice + a foreign id; a omitted entirely
      patch "/api/profile/pins", params: {pulse_ids: [b.id, b.id, 999_999]}, as: :json

      expect(response).to have_http_status(:ok)
      expect(hackr.pinned_pulses.to_a).to eq([b, a])
      expect(hackr.pulse_pins.ordered.pluck(:position)).to eq([0, 1])
    end
  end
end
