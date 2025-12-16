# frozen_string_literal: true

require "rails_helper"

RSpec.describe Terminal::Handlers::WireHandler do
  let(:hackr) { create(:grid_hackr) }
  let(:other_hackr) { create(:grid_hackr) }

  let(:input) { StringIO.new }
  let(:output) { StringIO.new }
  let(:session) { Terminal::Session.new(input, output) }

  before do
    session.authenticate(hackr)
  end

  after do
    session.realtime.clear_callbacks
  end

  subject(:handler) { described_class.new(session) }

  describe "#setup_realtime" do
    it "registers wire callback" do
      expect(session.realtime).to receive(:on_wire)

      handler.send(:setup_realtime)
    end
  end

  describe "#on_leave" do
    it "clears realtime callbacks" do
      handler.on_enter

      expect(session.realtime).to receive(:clear_callbacks).at_least(:once)

      handler.on_leave
    end
  end

  describe "#display_realtime_pulse" do
    before do
      handler.on_enter
      output.truncate(0)
      output.rewind
    end

    it "displays new pulse notification" do
      handler.send(:display_realtime_pulse, {
        type: "new_pulse",
        id: 123,
        hackr_alias: "PulseAuthor",
        content: "This is a test pulse from the network",
        pulsed_at: Time.current
      })

      expect(output.string).to include("NEW PULSE")
      expect(output.string).to include("@PulseAuthor")
      expect(output.string).to include("This is a test pulse")
    end

    it "truncates long content" do
      long_content = "A" * 100

      handler.send(:display_realtime_pulse, {
        type: "new_pulse",
        id: 123,
        hackr_alias: "Verbose",
        content: long_content,
        pulsed_at: Time.current
      })

      # Content should be truncated to 60 chars
      expect(output.string).to include("...")
      expect(output.string).not_to include("A" * 100)
    end

    it "suggests refresh command" do
      handler.send(:display_realtime_pulse, {
        type: "new_pulse",
        id: 123,
        hackr_alias: "Someone",
        content: "New pulse",
        pulsed_at: Time.current
      })

      expect(output.string).to include("refresh")
    end
  end

  describe "real-time pulse reception" do
    it "receives pulses from other users via pubsub" do
      received_events = []

      # Manually set up the callback to capture events
      session.realtime.on_wire { |event| received_events << event }

      # Simulate broadcast from PulsesController
      ActionCable.server.broadcast("pulse_wire", {
        type: "new_pulse",
        pulse: {
          id: 456,
          content: "Live pulse from the wire!",
          grid_hackr: {id: other_hackr.id, hackr_alias: other_hackr.hackr_alias},
          pulsed_at: Time.current
        }
      })

      sleep 0.1

      expect(received_events.size).to eq(1)
      expect(received_events.first[:content]).to eq("Live pulse from the wire!")
    end
  end
end
