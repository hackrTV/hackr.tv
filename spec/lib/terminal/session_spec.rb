# frozen_string_literal: true

require "rails_helper"

RSpec.describe Terminal::Session do
  let(:input) { StringIO.new }
  let(:output) { StringIO.new }

  subject(:session) { described_class.new(input, output) }

  after do
    session.realtime.clear_callbacks
  end

  describe "#initialize" do
    it "sets initial state to :connecting" do
      expect(session.state).to eq(:connecting)
    end

    it "starts without a hackr" do
      expect(session.hackr).to be_nil
    end

    it "creates a renderer" do
      expect(session.renderer).to be_a(Terminal::Renderer)
    end

    it "creates a realtime subscriber" do
      expect(session.realtime).to be_a(Terminal::RealtimeSubscriber)
    end

    it "starts in running state" do
      expect(session.running).to be true
    end
  end

  describe "#authenticate" do
    let(:hackr) { create(:grid_hackr) }

    it "sets the hackr" do
      session.authenticate(hackr)

      expect(session.hackr).to eq(hackr)
    end

    it "touches hackr activity" do
      expect(hackr).to receive(:touch_activity!)

      session.authenticate(hackr)
    end
  end

  describe "#logout" do
    let(:hackr) { create(:grid_hackr) }

    it "clears the hackr" do
      session.authenticate(hackr)
      session.logout

      expect(session.hackr).to be_nil
    end
  end

  describe "#authenticated?" do
    let(:hackr) { create(:grid_hackr) }

    it "returns false when not logged in" do
      expect(session.authenticated?).to be false
    end

    it "returns true when logged in" do
      session.authenticate(hackr)

      expect(session.authenticated?).to be true
    end
  end

  describe "#transition_to" do
    it "changes state to valid states" do
      session.transition_to(:menu)

      expect(session.state).to eq(:menu)
    end

    it "ignores invalid states" do
      session.transition_to(:menu)
      session.transition_to(:invalid_state)

      expect(session.state).to eq(:menu)
    end

    it "pushes to state stack by default" do
      session.transition_to(:menu)
      session.transition_to(:on_wire)

      session.go_back
      expect(session.state).to eq(:menu)
    end

    it "does not push when push_stack is false" do
      session.transition_to(:menu)
      session.transition_to(:on_wire, push_stack: false)

      session.go_back
      # Should go back to menu (the default when stack is empty)
      expect(session.state).to eq(:menu)
    end
  end

  describe "#go_back" do
    it "returns to previous state" do
      session.transition_to(:menu)
      session.transition_to(:in_codex)

      session.go_back

      expect(session.state).to eq(:menu)
    end

    it "returns to menu when stack is empty" do
      session.transition_to(:menu, push_stack: false)

      session.go_back

      expect(session.state).to eq(:menu)
    end
  end

  describe "#disconnect" do
    it "sets running to false" do
      session.disconnect

      expect(session.running).to be false
    end
  end

  describe "#println" do
    it "writes to output with newline" do
      session.println("test message")

      expect(output.string).to eq("test message\n")
    end

    it "writes empty newline when no argument" do
      session.println

      expect(output.string).to eq("\n")
    end
  end

  describe "#print" do
    it "writes to output without newline" do
      session.print("test")

      expect(output.string).to eq("test")
    end
  end

  describe "#gets" do
    it "reads from input" do
      input.puts("user input")
      input.rewind

      result = session.gets

      expect(result).to eq("user input\n")
    end
  end

  describe "#current_handler" do
    it "returns nil for connecting state" do
      expect(session.current_handler).to be_nil
    end

    it "returns MenuHandler for menu state" do
      session.transition_to(:menu)

      expect(session.current_handler).to be_a(Terminal::Handlers::MenuHandler)
    end

    it "returns GridHandler for in_grid state" do
      # GridHandler redirects to menu if not authenticated during on_enter
      # So we authenticate first
      hackr = create(:grid_hackr, :online)
      session.authenticate(hackr)
      session.transition_to(:in_grid)

      expect(session.current_handler).to be_a(Terminal::Handlers::GridHandler)
    end

    it "returns WireHandler for on_wire state" do
      session.transition_to(:on_wire)

      expect(session.current_handler).to be_a(Terminal::Handlers::WireHandler)
    end

    it "returns CodexHandler for in_codex state" do
      session.transition_to(:in_codex)

      expect(session.current_handler).to be_a(Terminal::Handlers::CodexHandler)
    end

    it "returns BandsHandler for in_bands state" do
      session.transition_to(:in_bands)

      expect(session.current_handler).to be_a(Terminal::Handlers::BandsHandler)
    end

    it "returns VaultHandler for in_vault state" do
      session.transition_to(:in_vault)

      expect(session.current_handler).to be_a(Terminal::Handlers::VaultHandler)
    end

    it "returns UplinkHandler for on_uplink state" do
      session.authenticate(create(:grid_hackr))
      session.transition_to(:on_uplink)

      expect(session.current_handler).to be_a(Terminal::Handlers::UplinkHandler)
    end

    it "returns LoginHandler for login state" do
      # LoginHandler requires input for perform_login during on_enter
      # Test the handler building logic directly
      handler = session.send(:build_handler, :login)

      expect(handler).to be_a(Terminal::Handlers::LoginHandler)
    end

    it "returns RegisterHandler for register state" do
      # RegisterHandler requires input during on_enter
      # Test the handler building logic directly
      handler = session.send(:build_handler, :register)

      expect(handler).to be_a(Terminal::Handlers::RegisterHandler)
    end

    it "caches handlers" do
      session.transition_to(:menu)
      handler1 = session.current_handler
      handler2 = session.current_handler

      expect(handler1).to equal(handler2)
    end
  end

  describe "global commands" do
    it "handles /menu command" do
      session.transition_to(:on_wire)
      session.send(:process_input, "/menu")

      expect(session.state).to eq(:menu)
    end

    it "handles /grid command" do
      # GridHandler requires authentication to stay in grid state
      hackr = create(:grid_hackr, :online)
      session.authenticate(hackr)
      session.transition_to(:menu)
      session.send(:process_input, "/grid")

      expect(session.state).to eq(:in_grid)
    end

    it "handles /wire command" do
      session.transition_to(:menu)
      session.send(:process_input, "/wire")

      expect(session.state).to eq(:on_wire)
    end

    it "handles /codex command" do
      session.transition_to(:menu)
      session.send(:process_input, "/codex")

      expect(session.state).to eq(:in_codex)
    end

    it "handles /bands command" do
      session.transition_to(:menu)
      session.send(:process_input, "/bands")

      expect(session.state).to eq(:in_bands)
    end

    it "handles /vault command" do
      session.transition_to(:menu)
      session.send(:process_input, "/vault")

      expect(session.state).to eq(:in_vault)
    end

    it "handles /uplink command" do
      session.authenticate(create(:grid_hackr))
      session.transition_to(:menu)
      session.send(:process_input, "/uplink")

      expect(session.state).to eq(:on_uplink)
    end

    it "handles quit command" do
      session.send(:process_input, "quit")

      expect(session.running).to be false
    end

    it "handles exit command" do
      session.send(:process_input, "exit")

      expect(session.running).to be false
    end

    it "handles back command" do
      session.transition_to(:menu)
      session.transition_to(:on_wire)
      session.send(:process_input, "back")

      expect(session.state).to eq(:menu)
    end

    it "handles b as shortcut for back" do
      session.transition_to(:menu)
      session.transition_to(:on_wire)
      session.send(:process_input, "b")

      expect(session.state).to eq(:menu)
    end
  end

  describe "color scheme commands" do
    before do
      session.transition_to(:menu)
    end

    it "handles amber command" do
      session.send(:process_input, "amber")

      expect(session.renderer.color_scheme).to eq(:amber)
    end

    it "handles green command" do
      session.send(:process_input, "green")

      expect(session.renderer.color_scheme).to eq(:green)
    end

    it "handles cga command" do
      session.send(:process_input, "cga")

      expect(session.renderer.color_scheme).to eq(:cga)
    end

    it "handles default command" do
      session.renderer.color_scheme = :amber
      session.send(:process_input, "default")

      expect(session.renderer.color_scheme).to eq(:default)
    end

    it "handles cyberpunk command as alias for default" do
      session.renderer.color_scheme = :amber
      session.send(:process_input, "cyberpunk")

      expect(session.renderer.color_scheme).to eq(:default)
    end

    it "outputs confirmation message" do
      output.truncate(0)
      session.send(:process_input, "amber")

      expect(output.string).to include("AMBER")
    end
  end

  describe "easter egg commands" do
    before do
      session.transition_to(:menu)
      output.truncate(0)
    end

    it "handles hack command" do
      session.send(:process_input, "hack")

      expect(output.string).to include("HACK")
    end

    it "handles root command" do
      session.send(:process_input, "root")

      expect(output.string).to include("Permission denied")
    end

    it "handles glitch command" do
      session.send(:process_input, "//test glitch")

      # Should output something (glitched text)
      expect(output.string).not_to be_empty
    end
  end

  describe "STATES" do
    it "includes all expected states" do
      expected_states = %i[
        connecting anonymous authenticated menu
        in_grid on_wire in_codex in_bands in_vault on_uplink
        login register
      ]

      expected_states.each do |state|
        expect(Terminal::Session::STATES).to include(state)
      end
    end
  end

  describe "GLOBAL_COMMANDS" do
    it "maps navigation commands to states" do
      expect(Terminal::Session::GLOBAL_COMMANDS["/menu"]).to eq(:menu)
      expect(Terminal::Session::GLOBAL_COMMANDS["/grid"]).to eq(:in_grid)
      expect(Terminal::Session::GLOBAL_COMMANDS["/wire"]).to eq(:on_wire)
    end

    it "maps exit commands to disconnect" do
      expect(Terminal::Session::GLOBAL_COMMANDS["quit"]).to eq(:disconnect)
      expect(Terminal::Session::GLOBAL_COMMANDS["exit"]).to eq(:disconnect)
    end
  end
end
