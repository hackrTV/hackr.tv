# frozen_string_literal: true

module Terminal
  module Handlers
    # Base class for all terminal handlers
    # Provides common functionality and interface for state handlers
    class BaseHandler
      attr_reader :session

      # @param session [Terminal::Session] The parent session
      def initialize(session)
        @session = session
        @displayed = false
      end

      # Convenience accessor for renderer
      # @return [Terminal::Renderer]
      def renderer
        session.renderer
      end

      # Convenience accessor for current hackr
      # @return [GridHackr, nil]
      def hackr
        session.hackr
      end

      # Check if session is authenticated
      # @return [Boolean]
      def authenticated?
        session.authenticated?
      end

      # Print with newline
      # @param text [String] Text to print
      def println(text = "")
        session.println(text)
      end

      # Print without newline
      # @param text [String] Text to print
      def print(text)
        session.print(text)
      end

      # Read a line of input
      # @return [String, nil]
      def gets
        session.gets
      end

      # Read password without echo
      # @return [String]
      def read_password
        session.read_password
      end

      # Called when transitioning to this state
      # Override in subclasses for state entry logic
      def on_enter
        @displayed = false
      end

      # Display the handler's content
      # Override in subclasses
      def display
        # Base implementation does nothing
        @displayed = true
      end

      # Handle user input
      # Override in subclasses
      # @param input [String] User input
      def handle(input)
        unknown_command(input)
      end

      # Get the prompt for this handler
      # Override in subclasses
      # @return [String]
      def prompt
        renderer.colorize("> ", :amber)
      end

      # Navigate back to previous state
      def go_back
        session.go_back
      end

      # Transition to a new state
      # @param state [Symbol] Target state
      def transition_to(state)
        session.transition_to(state)
      end

      # Show help for this handler
      # Override in subclasses
      def display_help
        println renderer.colorize("No help available for this section.", :gray)
      end

      protected

      # Display an error for unknown commands
      # @param cmd [String] The unknown command
      def unknown_command(cmd)
        println renderer.colorize("Unknown command: #{cmd}", :red)
        println renderer.colorize("Type 'help' for available commands or 'back' to return.", :gray)
      end

      # Display an error requiring authentication
      def require_auth_message
        println renderer.colorize("Authentication required.", :red)
        println renderer.colorize("Press [L] to login or [R] to register.", :gray)
      end

      # Parse a command with arguments
      # @param input [String] Full input string
      # @return [Array<String, String>] [command, args]
      def parse_command(input)
        parts = input.split(" ", 2)
        [parts[0]&.downcase, parts[1]]
      end

      # Format a relative time
      # @param time [Time] The time to format
      # @return [String]
      def time_ago(time)
        renderer.time_ago(time)
      end

      # Display a boxed message
      # @param title [String] Box title
      # @param content [String] Box content
      # @param color [Symbol] Box color
      def display_box(title, content, color: :cyan)
        println renderer.box(content, title: title, color: color)
      end

      # Display a header
      # @param text [String] Header text
      # @param color [Symbol] Header color
      def display_header(text, color: :cyan)
        println ""
        println renderer.header(text, color: color)
        println ""
      end

      # Display a divider
      # @param text [String, nil] Optional divider text
      def display_divider(text = nil)
        println renderer.divider(text)
      end

      # Clear the screen
      def clear_screen
        print renderer.clear_screen
      end
    end
  end
end
