# frozen_string_literal: true

module Terminal
  module Handlers
    # Handler for GridHackr authentication
    class LoginHandler < BaseHandler
      def on_enter
        super
        clear_screen
        display_banner
        perform_login
      end

      def display
        @displayed = true
      end

      def handle(input)
        # Login is handled in on_enter, any input here goes back
        go_back
      end

      def prompt
        renderer.colorize("login> ", :amber)
      end

      private

      def display_banner
        banner = Art.banner(:login)
        if banner.present?
          println renderer.colorize(banner, :amber)
        end
        println ""
      end

      def perform_login
        println renderer.colorize("  Enter your Grid credentials", :gray)
        println renderer.colorize("  (Press Enter with empty alias to cancel)", :gray)
        println ""

        # Get alias
        print renderer.colorize("  Hackr Alias: ", :amber)
        alias_input = gets&.chomp

        if alias_input.blank?
          println ""
          println renderer.colorize("  Login cancelled.", :gray)
          sleep 0.5
          go_back
          return
        end

        # Get password
        print renderer.colorize("  Password: ", :amber)
        password = read_password

        if password.blank?
          println ""
          println renderer.colorize("  Login cancelled.", :gray)
          sleep 0.5
          go_back
          return
        end

        # Authenticate
        hackr = GridHackr.find_by(hackr_alias: alias_input)

        if hackr&.authenticate(password)
          login_success(hackr)
        else
          login_failure(alias_input)
        end
      end

      def login_success(hackr)
        session.authenticate(hackr)
        hackr.touch_activity!

        println ""
        banner = Art.banner(:access_granted)
        if banner.present?
          println renderer.colorize(banner, :green)
        end
        println ""
        println renderer.colorize("  Welcome back, #{hackr.hackr_alias}.", :cyan)
        println renderer.colorize("  Your identity has been verified.", :gray)
        println ""

        sleep 1.5
        go_back
      end

      def login_failure(attempted_alias = nil)
        session.audit.track(:auth_failure, handler: :login, input: attempted_alias)
        println ""
        banner = Art.banner(:access_denied)
        if banner.present?
          println renderer.colorize(banner, :red)
        end
        println ""
        println renderer.colorize("  Invalid credentials.", :red)
        println renderer.colorize("  Access attempt logged by GovCorp PRISM.", :gray)
        println ""

        sleep 1.5
        go_back
      end
    end
  end
end
