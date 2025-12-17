# frozen_string_literal: true

require "io/console"

module Terminal
  # Main session state machine for terminal SSH connections
  # Manages state transitions, input handling, and handler dispatch
  class Session
    # Available session states
    STATES = %i[
      connecting
      anonymous
      authenticated
      menu
      in_grid
      on_wire
      in_codex
      in_bands
      in_vault
      login
      register
    ].freeze

    # Global commands available from any state
    GLOBAL_COMMANDS = {
      "/menu" => :menu,
      "/home" => :menu,
      "/grid" => :in_grid,
      "/wire" => :on_wire,
      "/codex" => :in_codex,
      "/bands" => :in_bands,
      "/vault" => :in_vault,
      "quit" => :disconnect,
      "exit" => :disconnect,
      "disconnect" => :disconnect
    }.freeze

    # Color scheme commands
    COLOR_SCHEME_COMMANDS = %w[amber green cga default cyberpunk].freeze

    attr_reader :state, :hackr, :renderer, :input, :output, :realtime
    attr_accessor :running

    # Initialize a new terminal session
    # @param input [IO] Input stream (default: $stdin)
    # @param output [IO] Output stream (default: $stdout)
    def initialize(input = $stdin, output = $stdout)
      @input = input
      @output = output
      @state = :connecting
      @hackr = nil
      @renderer = Renderer.new
      @handlers = {}
      @running = true
      @state_stack = []
      @realtime = RealtimeSubscriber.new(self)
    end

    # Main entry point - runs the terminal session
    def run
      setup_signal_handlers
      display_connection_banner
      transition_to(:menu)

      main_loop
    rescue Interrupt
      # Ctrl+C pressed
      println "\n#{renderer.colorize("Signal interrupted. Disconnecting...", :amber)}"
    rescue EOFError
      # Connection closed
    ensure
      cleanup
    end

    # Transition to a new state
    # @param new_state [Symbol] State to transition to
    # @param push_stack [Boolean] Whether to push current state to stack
    def transition_to(new_state, push_stack: true)
      return unless STATES.include?(new_state)

      # Notify old handler of state exit
      old_handler = @handlers[@state]
      old_handler&.on_leave if old_handler.respond_to?(:on_leave)

      # Push current state to stack for "back" navigation
      @state_stack.push(@state) if push_stack && @state != :connecting
      @state = new_state

      # Notify handler of state entry
      handler = current_handler
      handler&.on_enter if handler.respond_to?(:on_enter)
    end

    # Go back to previous state
    def go_back
      if @state_stack.any?
        previous = @state_stack.pop
        transition_to(previous, push_stack: false)
      else
        transition_to(:menu, push_stack: false)
      end
    end

    # Authenticate with a GridHackr account
    # @param hackr [GridHackr] The authenticated hackr
    def authenticate(hackr)
      @hackr = hackr
      @hackr.touch_activity! if @hackr.respond_to?(:touch_activity!)
    end

    # Log out current hackr
    def logout
      @hackr = nil
    end

    # Check if session is authenticated
    # @return [Boolean] True if logged in
    def authenticated?
      @hackr.present?
    end

    # Print output with newline
    # @param text [String] Text to print
    def println(text = "")
      output.puts text
    end

    # Print output without newline
    # @param text [String] Text to print
    def print(text)
      output.print text
    end

    # Read a line of input
    # @return [String, nil] Input line or nil on EOF
    def gets
      input.gets
    end

    # Read password (without echo if possible)
    # @return [String] Password input
    def read_password
      if input.respond_to?(:noecho)
        begin
          password = input.noecho(&:gets)&.chomp
          println "" # New line after hidden input
          password
        rescue Errno::ENOTTY
          # Not a TTY, fall back to regular input
          input.gets&.chomp
        end
      else
        input.gets&.chomp
      end
    end

    # Stop the session
    def disconnect
      @running = false
    end

    # Get the current handler for the active state
    # @return [Handlers::BaseHandler, nil] Current handler
    def current_handler
      @handlers[@state] ||= build_handler(@state)
    end

    private

    def setup_signal_handlers
      # Handle Ctrl+C gracefully
      trap("INT") { disconnect }
      trap("TERM") { disconnect }
    rescue ArgumentError
      # Signal trapping may not be available in all environments
    end

    def main_loop
      while @running
        handler = current_handler

        # Display handler content if it has a display method
        handler&.display if handler.respond_to?(:display) && should_display?

        # Show prompt and read input
        prompt_text = handler&.prompt || default_prompt
        print prompt_text
        output.flush

        line = gets&.chomp
        break if line.nil? # EOF

        process_input(line.strip)
      end
    end

    def process_input(line)
      return if line.empty?

      # Check for global commands first
      if GLOBAL_COMMANDS.key?(line.downcase)
        action = GLOBAL_COMMANDS[line.downcase]
        if action == :disconnect
          disconnect
        else
          transition_to(action)
        end
        return
      end

      # Handle "back" command
      if %w[back b].include?(line.downcase)
        go_back
        return
      end

      # Handle color scheme commands
      if handle_color_scheme(line.downcase)
        return
      end

      # Handle easter egg commands
      if EasterEggs.handle?(line)
        EasterEggs.execute(self, line)
        return
      end

      # Delegate to current handler
      handler = current_handler
      if handler
        handler.handle(line)
      else
        unknown_command(line)
      end
    end

    def should_display?
      # Only display on state entry, not every prompt
      # Handlers manage their own redisplay as needed
      @last_displayed_state != @state
    end

    def display_connection_banner
      println renderer.clear_screen

      # Load and display ASCII art banner
      banner = Art.banner(:connection)
      if banner.present?
        println renderer.colorize(banner, :cyan)
      end

      println renderer.colorize("           T E R M I N A L   A C C E S S   //   #{Time.current.year + 100}", :amber)
      println ""
      println renderer.colorize("  Connection established.", :green)
      println renderer.colorize("  Welcome to THE.CYBERPUL.SE network.", :gray)
      println ""

      # Random GovCorp intercept message (30% chance)
      if EasterEggs.show_intercept?
        println ""
        println renderer.colorize("  ╔════════════════════════════════════════════════════════════╗", :red)
        println renderer.colorize("  ║  #{EasterEggs.random_intercept.center(58)}  ║", :red)
        println renderer.colorize("  ╚════════════════════════════════════════════════════════════╝", :red)
      else
        println renderer.divider("GovCorp monitoring active", width: 65, color: :red)
      end
      println ""

      # Pause so user can see the banner before menu clears the screen
      print renderer.colorize("  Press ENTER to continue...", :gray)
      output.flush
      gets

      @last_displayed_state = :connecting
    end

    def build_handler(state)
      case state
      when :menu
        Handlers::MenuHandler.new(self)
      when :in_grid
        Handlers::GridHandler.new(self)
      when :on_wire
        Handlers::WireHandler.new(self)
      when :in_codex
        Handlers::CodexHandler.new(self)
      when :in_bands
        Handlers::BandsHandler.new(self)
      when :in_vault
        Handlers::VaultHandler.new(self)
      when :login
        Handlers::LoginHandler.new(self)
      when :register
        Handlers::RegisterHandler.new(self)
      end
    end

    def default_prompt
      renderer.colorize("hackr.tv> ", :amber)
    end

    def unknown_command(cmd)
      println renderer.colorize("Unknown command: #{cmd}. Type 'help' for assistance.", :red)
    end

    def handle_color_scheme(cmd)
      scheme = case cmd
      when "amber" then :amber
      when "green" then :green
      when "cga" then :cga
      when "default", "cyberpunk" then :default
      else return false
      end

      renderer.color_scheme = scheme
      println ""
      println renderer.colorize("Color scheme set to: #{scheme.upcase}", :cyan)
      println renderer.colorize("All terminal output will now use #{scheme} colors.", :gray)
      println ""
      true
    end

    def cleanup
      # Stop real-time subscriber
      @realtime.stop if @realtime.running?

      # Clean up resources on disconnect
      println ""
      println renderer.colorize("Disconnected from THE.CYBERPUL.SE", :amber)
      println renderer.colorize("Signal lost.", :gray)
    end
  end
end
