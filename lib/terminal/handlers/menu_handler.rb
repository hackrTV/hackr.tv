# frozen_string_literal: true

module Terminal
  module Handlers
    # Main menu handler - displays the primary navigation
    class MenuHandler < BaseHandler
      # Menu items configuration
      # key => { label: display_label, state: target_state, auth: requires_auth }
      MENU_ITEMS = {
        "1" => {label: "THE PULSE GRID", state: :in_grid, auth: true, description: "Enter the MUD"},
        "2" => {label: "PulseWire", state: :on_wire, auth: false, description: "Social feed"},
        "3" => {label: "The Codex", state: :in_codex, auth: false, description: "Knowledge archive"},
        "4" => {label: "hackr.fm", state: :in_bands, auth: false, description: "Band profiles"},
        "5" => {label: "Pulse Vault", state: :in_vault, auth: false, description: "Track listings"},
        "6" => {label: "Uplink", state: :on_uplink, auth: true, description: "Real-time signal"}
      }.freeze

      AUTH_ITEMS = {
        "L" => {label: "Login", state: :login, show_when: :anonymous},
        "R" => {label: "Register", state: :register, show_when: :anonymous},
        "O" => {label: "Logout", action: :logout, show_when: :authenticated}
      }.freeze

      def on_enter
        super
        @displayed = false
      end

      def display
        clear_screen

        # Main banner
        display_main_banner

        println ""
        println renderer.double_line(width: 60, color: :purple)
        println renderer.colorize("  MAIN SYSTEMS", :amber)
        println renderer.double_line(width: 60, color: :purple)
        println ""

        # Main menu items
        MENU_ITEMS.each do |key, item|
          disabled = item[:auth] && !authenticated?
          note = disabled ? "[LOGIN REQUIRED]" : nil
          println renderer.menu_item(key, item[:label], disabled: disabled, note: note)
        end

        println ""
        println renderer.divider("ACCOUNT", width: 60, color: :gray)
        println ""

        # Auth-dependent items
        AUTH_ITEMS.each do |key, item|
          show = case item[:show_when]
          when :anonymous then !authenticated?
          when :authenticated then authenticated?
          else true
          end
          println renderer.menu_item(key, item[:label]) if show
        end

        println renderer.menu_item("Q", "Disconnect")

        println ""
        println renderer.double_line(width: 60, color: :purple)

        # Show login status
        if authenticated?
          println renderer.colorize("  Logged in as: #{hackr.hackr_alias}", :green)
        else
          println renderer.colorize("  Anonymous Mode - Login for full access", :gray)
        end

        println ""
        @displayed = true
      end

      def handle(input)
        key = input.upcase

        # Check main menu items
        if MENU_ITEMS.key?(key)
          item = MENU_ITEMS[key]
          if item[:auth] && !authenticated?
            println ""
            require_auth_message
            return
          end
          transition_to(item[:state])
          return
        end

        # Check auth items
        if AUTH_ITEMS.key?(key)
          item = AUTH_ITEMS[key]
          if item[:action] == :logout
            perform_logout
          else
            transition_to(item[:state])
          end
          return
        end

        # Handle quit
        if key == "Q"
          session.disconnect
          return
        end

        # Handle help
        if key == "HELP" || key == "?"
          display_help
          return
        end

        # Handle who command
        if key == "WHO"
          display_online_users
          return
        end

        unknown_command(input)
      end

      def prompt
        renderer.colorize("hackr.tv> ", :amber)
      end

      def display_help
        println ""
        println renderer.header("HELP", color: :cyan)
        println ""
        println renderer.colorize("  Navigation:", :amber)
        println "    Type a number (1-6) to enter a system"
        println "    Type 'L' to login, 'R' to register"
        println "    Type 'Q' to disconnect"
        println ""
        println renderer.colorize("  Global Commands (work anywhere):", :amber)
        println "    /menu    - Return to this menu"
        println "    /grid    - Jump to THE PULSE GRID"
        println "    /wire    - Jump to PulseWire"
        println "    /codex   - Jump to The Codex"
        println "    /bands   - Jump to hackr.fm"
        println "    /vault   - Jump to Pulse Vault"
        println "    /uplink  - Connect to Uplink"
        println "    back     - Go back to previous screen"
        println "    who      - See who's online"
        println ""
      end

      private

      def display_main_banner
        banner = Art.banner(:menu)
        if banner.present?
          println renderer.colorize(banner, :cyan)
        end
      end

      def perform_logout
        if authenticated?
          alias_name = hackr.hackr_alias
          session.logout
          println ""
          println renderer.colorize("Logged out. Goodbye, #{alias_name}.", :amber)
          println ""
          @displayed = false
          display
        end
      end

      def display_online_users
        println ""
        println renderer.header("WHO'S ONLINE", color: :cyan)
        println ""

        # Get recently active hackrs
        online = GridHackr.recently_active.includes(:current_room).limit(20)

        if online.any?
          online.each do |h|
            location = h.current_room&.name || "Unknown"
            status = (h == hackr) ? renderer.colorize("(you)", :green) : ""
            println "  #{renderer.colorize(h.hackr_alias, :purple)} - #{renderer.colorize(location, :gray)} #{status}"
          end
        else
          println renderer.colorize("  No one is online.", :gray)
        end

        println ""
        println renderer.colorize("  #{online.count} hackr(s) connected", :gray)
        println ""
      end
    end
  end
end
