# frozen_string_literal: true

# Terminal SSH Access System for hackr.tv
# Provides a BBS-style terminal interface to THE.CYBERPUL.SE universe

require_relative "terminal/ansi"
require_relative "terminal/renderer"
require_relative "terminal/password"
require_relative "terminal/art"
require_relative "terminal/effects"
require_relative "terminal/easter_eggs"
require_relative "terminal/realtime_subscriber"
require_relative "terminal/session"

# Handlers
require_relative "terminal/handlers/base_handler"
require_relative "terminal/handlers/menu_handler"
require_relative "terminal/handlers/grid_handler"
require_relative "terminal/handlers/wire_handler"
require_relative "terminal/handlers/codex_handler"
require_relative "terminal/handlers/bands_handler"
require_relative "terminal/handlers/vault_handler"
require_relative "terminal/handlers/login_handler"
require_relative "terminal/handlers/register_handler"
require_relative "terminal/handlers/uplink_handler"

module Terminal
  VERSION = "1.0.0"

  class << self
    # Start a new terminal session with the given IO streams
    # @param input [IO] Input stream (default: $stdin)
    # @param output [IO] Output stream (default: $stdout)
    # @return [Session] The session instance
    def start(input: $stdin, output: $stdout)
      session = Session.new(input, output)
      session.run
      session
    end
  end
end
