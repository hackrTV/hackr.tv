# frozen_string_literal: true

module Terminal
  module Handlers
    # Handler for new GridHackr registration
    class RegisterHandler < BaseHandler
      def on_enter
        super
        clear_screen
        display_banner

        # Check prerelease mode
        if defined?(APP_SETTINGS) && APP_SETTINGS[:prerelease_mode].present?
          println renderer.colorize("  Registration temporarily disabled during #{APP_SETTINGS[:prerelease_mode]} phase.", :red)
          println renderer.colorize("  Please contact an administrator for access.", :gray)
          println ""
          sleep 1.5
          go_back
          return
        end

        perform_registration
      end

      def display
        @displayed = true
      end

      def handle(input)
        go_back
      end

      def prompt
        renderer.colorize("register> ", :cyan)
      end

      private

      def display_banner
        banner = Art.banner(:register)
        if banner.present?
          println renderer.colorize(banner, :cyan)
        end
        println ""
      end

      def perform_registration
        println renderer.colorize("  Choose your identity in THE PULSE GRID", :gray)
        println renderer.colorize("  (Press Enter with empty alias to cancel)", :gray)
        println ""

        # Get alias
        print renderer.colorize("  Hackr Alias: ", :amber)
        alias_input = gets&.chomp

        if alias_input.blank?
          cancel_registration
          return
        end

        # Validate alias uniqueness
        if GridHackr.exists?(["LOWER(hackr_alias) = ?", alias_input.downcase])
          println ""
          println renderer.colorize("  That alias is already taken. Choose another.", :red)
          println ""
          sleep 1
          perform_registration
          return
        end

        # Get password
        print renderer.colorize("  Password: ", :amber)
        password = read_password

        if password.blank?
          cancel_registration
          return
        end

        if password.length < 6
          println ""
          println renderer.colorize("  Password must be at least 6 characters.", :red)
          println ""
          sleep 1
          perform_registration
          return
        end

        # Confirm password
        print renderer.colorize("  Confirm Password: ", :amber)
        password_confirm = read_password

        if password != password_confirm
          println ""
          println renderer.colorize("  Passwords do not match.", :red)
          println ""
          sleep 1
          perform_registration
          return
        end

        # Create the hackr
        create_hackr(alias_input, password)
      end

      def create_hackr(alias_input, password)
        # Find starting room
        starting_room = GridRoom.joins(:grid_zone)
          .where(grid_zones: {slug: "hackr_tv_central"})
          .where(room_type: "hub")
          .first

        # Fallback to any hub room
        starting_room ||= GridRoom.where(room_type: "hub").first

        hackr = GridHackr.new(
          hackr_alias: alias_input,
          password: password,
          password_confirmation: password,
          current_room: starting_room,
          role: "operative"
        )

        if hackr.save
          registration_success(hackr)
        else
          registration_failure(hackr)
        end
      end

      def registration_success(hackr)
        session.authenticate(hackr)
        hackr.touch_activity!

        clear_screen

        # Display welcome sequence
        println ""
        banner = Art.banner(:welcome)
        if banner.present?
          println renderer.colorize(banner, :green)
        end
        println ""
        println renderer.colorize("  Identity confirmed: #{hackr.hackr_alias}", :cyan)
        println renderer.colorize("  Status: OPERATIVE", :amber)
        println renderer.colorize("  Faction: Fracture Network", :purple)
        println ""
        println renderer.divider(width: 60, color: :gray)
        println ""
        println renderer.colorize("  \"GovCorp sees all, but the Grid remembers.\"", :gray)
        println renderer.colorize("  \"Your journey begins now...\"", :gray)
        println ""
        println renderer.divider(width: 60, color: :gray)
        println ""
        println renderer.colorize("  Press Enter to continue...", :amber)

        gets

        go_back
      end

      def registration_failure(hackr)
        println ""
        banner = Art.banner(:access_denied)
        if banner.present?
          println renderer.colorize(banner, :red)
        end
        println ""
        println renderer.colorize("  Registration failed:", :red)
        println ""

        hackr.errors.full_messages.each do |msg|
          println renderer.colorize("  - #{msg}", :red)
        end

        println ""
        sleep 2
        go_back
      end

      def cancel_registration
        println ""
        println renderer.colorize("  Registration cancelled.", :gray)
        sleep 0.5
        go_back
      end
    end
  end
end
