# frozen_string_literal: true

require "rails_helper"

RSpec.describe Terminal::Handlers::UplinkHandler do
  let(:hackr) { create(:grid_hackr) }
  let(:other_hackr) { create(:grid_hackr) }
  let!(:channel) { create(:chat_channel, name: "Ambient", slug: "ambient", is_active: true) }

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

  describe "#on_enter" do
    it "displays the banner and joins the first channel" do
      handler.on_enter

      expect(output.string).to include("UPLINK")
      expect(output.string).to include("#ambient")
    end

    it "requires authentication" do
      session.logout
      handler.on_enter

      expect(output.string).to include("Authentication required")
    end
  end

  describe "#on_leave" do
    it "clears uplink subscriptions" do
      handler.on_enter

      expect(session.realtime).to receive(:unsubscribe_uplink).at_least(:once)
      expect(session.realtime).to receive(:clear_uplink_callback)

      handler.on_leave
    end
  end

  describe "channel commands" do
    before do
      handler.on_enter
      output.truncate(0)
      output.rewind
    end

    describe "channels command" do
      it "lists available channels" do
        handler.handle("channels")

        expect(output.string).to include("UPLINK CHANNELS")
        expect(output.string).to include("#ambient")
      end

      it "works with ch alias" do
        handler.handle("ch")

        expect(output.string).to include("UPLINK CHANNELS")
      end
    end

    describe "join command" do
      let!(:other_channel) { create(:chat_channel, name: "Live", slug: "live", is_active: true) }

      it "switches to a channel" do
        handler.handle("join live")

        expect(output.string).to include("Joined #live")
      end

      it "handles channel not found" do
        handler.handle("join nonexistent")

        expect(output.string).to include("Channel not found")
      end

      it "strips # prefix from channel name" do
        handler.handle("join #live")

        expect(output.string).to include("Joined #live")
      end

      it "shows usage when no channel specified" do
        handler.handle("join")

        expect(output.string).to include("Usage:")
      end
    end
  end

  describe "messaging" do
    before do
      handler.on_enter
      output.truncate(0)
      output.rewind
    end

    it "sends a message" do
      handler.handle("say Hello world")

      expect(ChatMessage.last.content).to eq("Hello world")
      expect(ChatMessage.last.chat_channel).to eq(channel)
      expect(ChatMessage.last.grid_hackr).to eq(hackr)
    end

    it "sends bare text as a message" do
      handler.handle("Hello from the terminal")

      expect(ChatMessage.last.content).to eq("Hello from the terminal")
    end

    it "rejects messages when squelched" do
      create(:user_punishment, grid_hackr: hackr, issued_by: other_hackr, punishment_type: "squelch")

      handler.handle("say test")

      expect(output.string).to include("squelched")
      expect(ChatMessage.count).to eq(0)
    end

    it "rejects messages when blackedout" do
      create(:user_punishment, grid_hackr: hackr, issued_by: other_hackr, punishment_type: "blackout")

      handler.handle("say test")

      expect(output.string).to include("blackedout")
      expect(ChatMessage.count).to eq(0)
    end

    it "enforces slow mode" do
      channel.update!(slow_mode_seconds: 60)
      # Reload the cached channel reference in the handler
      handler.instance_variable_get(:@current_channel).reload

      handler.handle("say first message")
      output.truncate(0)
      output.rewind
      handler.handle("say second message")

      expect(output.string).to include("Slow mode")
      expect(ChatMessage.count).to eq(1)
    end

    it "rejects messages over 512 characters" do
      handler.handle("say #{"A" * 513}")

      expect(output.string).to include("too long")
      expect(ChatMessage.count).to eq(0)
    end

    it "shows usage for empty say command" do
      handler.handle("say")

      expect(output.string).to include("Usage:")
    end
  end

  describe "display commands" do
    before do
      handler.on_enter
      output.truncate(0)
      output.rewind
    end

    describe "history command" do
      it "shows recent messages" do
        create(:chat_message, chat_channel: channel, grid_hackr: other_hackr, content: "Test message")
        handler.send(:load_history)
        handler.handle("history")

        expect(output.string).to include("Test message")
        expect(output.string).to include(other_hackr.hackr_alias)
      end

      it "hides dropped messages" do
        create(:chat_message, chat_channel: channel, grid_hackr: other_hackr, content: "Visible")
        create(:chat_message, chat_channel: channel, grid_hackr: other_hackr, content: "Dropped", dropped: true)
        handler.send(:load_history)
        handler.handle("h")

        expect(output.string).to include("Visible")
        expect(output.string).not_to include("Dropped")
      end
    end

    describe "who command" do
      it "shows channel info" do
        handler.handle("who")

        expect(output.string).to include("#ambient")
        expect(output.string).to include("Ambient")
      end
    end

    describe "help command" do
      it "shows help text" do
        handler.handle("help")

        expect(output.string).to include("UPLINK COMMANDS")
        expect(output.string).to include("channels")
        expect(output.string).to include("join")
        expect(output.string).to include("say")
      end
    end
  end

  describe "real-time packet reception" do
    before do
      handler.on_enter
      output.truncate(0)
      output.rewind
    end

    it "displays incoming packets from other users" do
      handler.send(:display_realtime_packet, {
        type: "new_packet",
        id: 123,
        hackr_alias: "NetRunner",
        role: "operative",
        content: "Live from the uplink",
        created_at: Time.current.iso8601
      })

      expect(output.string).to include("@NetRunner")
      expect(output.string).to include("Live from the uplink")
    end

    it "shows role badges for admins" do
      handler.send(:display_realtime_packet, {
        type: "new_packet",
        id: 124,
        hackr_alias: "AdminUser",
        role: "admin",
        content: "Admin message",
        created_at: Time.current.iso8601
      })

      expect(output.string).to include("[A]")
    end

    it "receives packets via pubsub" do
      received_events = []

      session.realtime.on_uplink { |event| received_events << event }
      session.realtime.subscribe_uplink(channel.stream_name)

      ActionCable.server.broadcast(channel.stream_name, {
        type: "new_packet",
        packet: {
          id: 456,
          content: "Live from the network!",
          dropped: false,
          grid_hackr: {id: other_hackr.id, hackr_alias: other_hackr.hackr_alias, role: "operative"},
          created_at: Time.current.iso8601
        }
      })

      sleep 0.1

      expect(received_events.size).to eq(1)
      expect(received_events.first[:content]).to eq("Live from the network!")
    end

    it "receives same-user packets sent from other clients (e.g. web)" do
      received_events = []

      session.realtime.on_uplink { |event| received_events << event }
      session.realtime.subscribe_uplink(channel.stream_name)

      ActionCable.server.broadcast(channel.stream_name, {
        type: "new_packet",
        packet: {
          id: 789,
          content: "From the web client",
          dropped: false,
          grid_hackr: {id: hackr.id, hackr_alias: hackr.hackr_alias, role: hackr.role},
          created_at: Time.current.iso8601
        }
      })

      sleep 0.1

      expect(received_events.size).to eq(1)
      expect(received_events.first[:content]).to eq("From the web client")
    end

    it "filters packets sent from this terminal session" do
      received_events = []

      session.realtime.on_uplink { |event| received_events << event }
      session.realtime.subscribe_uplink(channel.stream_name)
      session.realtime.track_local_packet(999)

      ActionCable.server.broadcast(channel.stream_name, {
        type: "new_packet",
        packet: {
          id: 999,
          content: "Sent from this terminal",
          dropped: false,
          grid_hackr: {id: hackr.id, hackr_alias: hackr.hackr_alias, role: hackr.role},
          created_at: Time.current.iso8601
        }
      })

      sleep 0.1

      expect(received_events).to be_empty
    end

    it "suppresses own-hackr packets during active send (race guard)" do
      received_events = []

      session.realtime.on_uplink { |event| received_events << event }
      session.realtime.subscribe_uplink(channel.stream_name)

      # Simulate the race: suppress is set before save, but broadcast arrives
      # before track_local_packet registers the ID
      session.realtime.suppress_own_uplink_packets!

      ActionCable.server.broadcast(channel.stream_name, {
        type: "new_packet",
        packet: {
          id: 888,
          content: "Race condition packet",
          dropped: false,
          grid_hackr: {id: hackr.id, hackr_alias: hackr.hackr_alias, role: hackr.role},
          created_at: Time.current.iso8601
        }
      })

      sleep 0.1

      expect(received_events).to be_empty

      # After tracking, suppression ends and other-user packets come through again
      session.realtime.track_local_packet(888)

      ActionCable.server.broadcast(channel.stream_name, {
        type: "new_packet",
        packet: {
          id: 890,
          content: "From another user after suppression ends",
          dropped: false,
          grid_hackr: {id: other_hackr.id, hackr_alias: other_hackr.hackr_alias, role: "operative"},
          created_at: Time.current.iso8601
        }
      })

      sleep 0.1

      expect(received_events.size).to eq(1)
      expect(received_events.first[:content]).to eq("From another user after suppression ends")
    end
  end

  describe "#prompt" do
    it "includes channel name" do
      handler.on_enter

      expect(handler.prompt).to include("#ambient")
    end
  end
end
