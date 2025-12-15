# frozen_string_literal: true

module Terminal
  module Handlers
    # Handler for THE PULSE GRID MUD
    # Integrates with existing Grid::CommandParser for command execution
    class GridHandler < BaseHandler
      def on_enter
        super

        unless authenticated?
          require_auth_message
          go_back
          return
        end

        clear_screen
        display_banner
        execute_look
        setup_realtime
      end

      def on_leave
        # Stop receiving real-time updates when leaving Grid
        session.realtime.clear_callbacks
        super if defined?(super)
      end

      def display
        # Grid doesn't redisplay on every prompt - it's command-driven
        @displayed = true
      end

      def handle(input)
        cmd = input.downcase.strip

        case cmd
        when "back", "menu"
          go_back
        when "help", "?"
          display_help
        else
          execute_command(input)
        end
      end

      def prompt
        room_name = hackr&.current_room&.name || "VOID"
        "#{renderer.colorize("[#{room_name}]", :purple)} #{renderer.colorize(">", :cyan)} "
      end

      def display_help
        println ""
        println renderer.header("PULSE GRID COMMANDS", color: :cyan)
        println ""
        println renderer.colorize("  Movement:", :amber)
        println "    look (l)          - Examine your surroundings"
        println "    go <direction>    - Move in a direction"
        println "    north/south/east/west/up/down (n/s/e/w/u/d)"
        println ""
        println renderer.colorize("  Items:", :amber)
        println "    inventory (i)     - View your inventory"
        println "    take <item>       - Pick up an item"
        println "    drop <item>       - Drop an item"
        println "    examine <target>  - Inspect an item or NPC"
        println ""
        println renderer.colorize("  Interaction:", :amber)
        println "    say <message>     - Speak to the room"
        println "    talk <npc>        - Start conversation with NPC"
        println "    ask <npc> about <topic> - Ask NPC about a topic"
        println ""
        println renderer.colorize("  Other:", :amber)
        println "    who               - See who's online"
        println "    clear             - Clear the screen"
        println "    back              - Return to main menu"
        println ""
      end

      private

      def display_banner
        banner = Art.banner(:grid)
        if banner.present?
          println renderer.colorize(banner, :purple)
        end
        println ""
      end

      def execute_look
        execute_command("look")
      end

      def execute_command(input)
        return unless hackr

        # Touch activity for online status
        hackr.touch_activity!

        # Use the existing Grid::CommandParser
        parser = Grid::CommandParser.new(hackr, input)
        result = parser.execute

        # Convert HTML output to ANSI
        if result[:output].present?
          ansi_output = renderer.html_to_ansi(result[:output])
          println ansi_output
        end

        # Broadcast event to other players (web and terminal)
        broadcast_event(result[:event]) if result[:event]

        # Reload hackr to get updated room after movement
        if result[:event]&.dig(:type) == "movement"
          hackr.reload
          # Update real-time monitoring to new room
          update_room_monitoring
        end
      end

      def broadcast_event(event)
        return unless event

        case event[:type]
        when "movement"
          # Broadcast to both old and new rooms
          if event[:from_room_id]
            room = GridRoom.find_by(id: event[:from_room_id])
            GridChannel.broadcast_to(room, event) if room
          end
          if event[:to_room_id]
            room = GridRoom.find_by(id: event[:to_room_id])
            GridChannel.broadcast_to(room, event) if room
          end
        when "say", "take", "drop"
          # Broadcast to current room
          GridChannel.broadcast_to(hackr.current_room, event) if hackr.current_room
        end
      end

      def setup_realtime
        # Register callback for room events
        session.realtime.on_grid do |event|
          display_realtime_event(event)
        end

        # Monitor current room
        update_room_monitoring
      end

      def update_room_monitoring
        return unless hackr&.current_room

        session.realtime.monitor_room(hackr.current_room.id)
      end

      def display_realtime_event(event)
        return unless event

        println ""

        case event[:type]
        when "say"
          println renderer.colorize("#{event[:hackr_alias]} says:", :purple) + " \"#{event[:content]}\""
        when "arrival"
          println renderer.colorize(event[:hackr_alias].to_s, :cyan) + renderer.colorize(" arrives from the #{event[:direction]}.", :gray)
        when "departure"
          println renderer.colorize(event[:hackr_alias].to_s, :cyan) + renderer.colorize(" leaves to the #{event[:direction]}.", :gray)
        when "take"
          println renderer.colorize(event[:hackr_alias].to_s, :cyan) + renderer.colorize(" picks up #{event[:item]}.", :gray)
        when "drop"
          println renderer.colorize(event[:hackr_alias].to_s, :cyan) + renderer.colorize(" drops #{event[:item]}.", :gray)
        end

        println ""
      end
    end
  end
end
