require "rails_helper"

RSpec.describe OverlayChannel, type: :channel do
  before do
    stub_connection
  end

  describe "#subscribed" do
    it "successfully subscribes" do
      subscribe

      expect(subscription).to be_confirmed
    end

    it "streams from overlay_updates" do
      subscribe

      expect(subscription).to have_stream_from("overlay_updates")
    end
  end

  describe "#unsubscribed" do
    it "successfully unsubscribes" do
      subscribe
      unsubscribe

      expect(subscription).not_to have_streams
    end
  end

  describe "#receive" do
    it "receives data without error" do
      subscribe

      # Currently receive is a no-op, but test it doesn't raise
      expect {
        perform(:receive, {type: "test"})
      }.not_to raise_error
    end
  end
end
