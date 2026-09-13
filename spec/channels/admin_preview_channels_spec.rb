require "rails_helper"

# Admin preview (controlled rollout): the WIRE + grid cable surfaces are
# admin-only for now — these specs pin the channel-side gate. Remove
# alongside the channel checks when the surfaces reopen.
RSpec.describe "Admin preview channel gating", type: :channel do
  let(:room) { create(:grid_room) }
  let(:hackr) { create(:grid_hackr, current_room: room) }
  let(:admin) { create(:grid_hackr, :admin, current_room: room) }

  describe PulseWireChannel do
    it "rejects non-admin subscribers" do
      stub_connection current_hackr: hackr
      subscribe
      expect(subscription).to be_rejected
    end

    it "confirms admins" do
      stub_connection current_hackr: admin
      subscribe
      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("pulse_wire")
    end
  end

  describe GridChannel do
    it "rejects non-admin subscribers" do
      stub_connection current_hackr: hackr
      subscribe
      expect(subscription).to be_rejected
    end

    it "confirms admins with a room" do
      stub_connection current_hackr: admin
      subscribe
      expect(subscription).to be_confirmed
    end
  end

  describe ZoneChannel do
    it "rejects non-admin subscribers" do
      stub_connection current_hackr: hackr
      subscribe
      expect(subscription).to be_rejected
    end

    it "confirms admins with a zone" do
      stub_connection current_hackr: admin
      subscribe
      expect(subscription).to be_confirmed
    end
  end
end
