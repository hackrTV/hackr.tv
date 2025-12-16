# frozen_string_literal: true

module Terminal
  module Handlers
    # Handler for PulseWire social network
    class WireHandler < BaseHandler
      ITEMS_PER_PAGE = 10

      def on_enter
        super
        @current_page = 1
        clear_screen
        display_banner
        display_timeline
        setup_realtime
      end

      def on_leave
        # Stop receiving real-time updates when leaving Wire
        session.realtime.clear_callbacks
        super if defined?(super)
      end

      def display
        @displayed = true
      end

      def handle(input)
        cmd, args = parse_command(input)

        case cmd
        when "back", "menu"
          go_back
        when "read", "r", "refresh"
          @current_page = args&.to_i || 1
          @current_page = 1 if @current_page < 1
          display_timeline
        when "next", "n"
          @current_page += 1
          display_timeline
        when "prev", "p"
          @current_page = [@current_page - 1, 1].max
          display_timeline
        when "post", "pulse"
          post_pulse(args)
        when "echo", "e"
          echo_pulse(args&.to_i)
        when "view", "v"
          view_pulse(args&.to_i)
        when "splice", "reply", "s"
          splice_pulse(args)
        when "user", "u"
          view_user(args)
        when "help", "?"
          display_help
        else
          unknown_command(input)
        end
      end

      def prompt
        renderer.colorize("wire> ", :cyan)
      end

      def display_help
        println ""
        println renderer.header("PULSEWIRE COMMANDS", color: :cyan)
        println ""
        println renderer.colorize("  Browsing:", :amber)
        println "    read [page]       - View timeline (default: page 1)"
        println "    next (n)          - Next page"
        println "    prev (p)          - Previous page"
        println "    view <id>         - View pulse and thread"
        println "    user <alias>      - View user's pulses"
        println ""
        println renderer.colorize("  Interaction (requires login):", :amber)
        println "    post <message>    - Broadcast a new pulse"
        println "    echo <id>         - Echo/rebroadcast a pulse"
        println "    splice <id> <msg> - Reply to a pulse"
        println ""
        println renderer.colorize("  Other:", :amber)
        println "    refresh           - Reload the timeline"
        println "    back              - Return to main menu"
        println ""
      end

      private

      def display_banner
        banner = Art.banner(:wire)
        if banner.present?
          println renderer.colorize(banner, :cyan)
        end
      end

      def setup_realtime
        # Register callback for new pulses - subscribes immediately
        session.realtime.on_wire do |event|
          display_realtime_pulse(event)
        end
      end

      def display_realtime_pulse(event)
        # Display notification above the prompt (runs in Action Cable thread)
        session.output.puts ""
        session.output.puts renderer.colorize("  ═══ NEW PULSE ═══", :amber)
        session.output.puts "  #{renderer.colorize("@#{event[:hackr_alias]}", :purple)}: #{event[:content].truncate(60)}"
        session.output.puts renderer.colorize("  Type 'refresh' to see full timeline", :gray)
        session.output.puts ""
        # Reprint the prompt and flush so user sees it immediately
        session.output.print prompt
        session.output.flush
      end

      def display_timeline
        pulses = Pulse.where(signal_dropped: false)
          .where(parent_pulse_id: nil)
          .includes(:grid_hackr)
          .order(pulsed_at: :desc)
          .limit(ITEMS_PER_PAGE)
          .offset((@current_page - 1) * ITEMS_PER_PAGE)

        total_count = Pulse.where(signal_dropped: false).where(parent_pulse_id: nil).count
        total_pages = (total_count.to_f / ITEMS_PER_PAGE).ceil

        println ""
        println renderer.divider("FEED", width: 60, color: :cyan)
        println ""

        if pulses.empty?
          println renderer.colorize("  No pulses found.", :gray)
        else
          pulses.each do |pulse|
            display_pulse(pulse)
          end
        end

        println ""
        println renderer.divider("Page #{@current_page}/#{total_pages} | #{total_count} pulses", width: 60, color: :gray)
        println ""
        println renderer.colorize("  [n]ext [p]rev [v]iew <id> [post] <msg> [echo] <id> [back]", :gray)
        println ""
      end

      def display_pulse(pulse, indent: 0)
        prefix = "  " * indent
        hackr_name = pulse.grid_hackr&.hackr_alias || "Unknown"
        time_display = time_ago(pulse.pulsed_at)

        println ""
        println "#{prefix}#{renderer.colorize("##{pulse.id}", :amber)} #{renderer.colorize("@#{hackr_name}", :purple)} - #{renderer.colorize(time_display, :gray)}"
        println "#{prefix}  #{pulse.content}"
        println "#{prefix}  #{renderer.colorize("\u21BA #{pulse.echo_count} echoes", :cyan)} | #{renderer.colorize("\u2937 #{pulse.splices.count} splices", :green)}"
      end

      def post_pulse(content)
        unless authenticated?
          require_auth_message
          return
        end

        if content.blank?
          println renderer.colorize("Usage: post <message>", :amber)
          return
        end

        if content.length > 256
          println renderer.colorize("Pulse too long! Maximum 256 characters.", :red)
          return
        end

        pulse = hackr.pulses.build(content: content)

        println ""
        if pulse.save
          println renderer.colorize("Pulse broadcast successfully!", :green)
        else
          println renderer.colorize("Failed to post: #{pulse.errors.full_messages.join(", ")}", :red)
        end
        println ""
      end

      def echo_pulse(pulse_id)
        unless authenticated?
          require_auth_message
          return
        end

        unless pulse_id
          println renderer.colorize("Usage: echo <id>", :amber)
          return
        end

        pulse = Pulse.find_by(id: pulse_id)
        unless pulse
          println renderer.colorize("Pulse not found.", :red)
          return
        end

        existing = hackr.echoes.find_by(pulse: pulse)
        if existing
          existing.destroy
          println renderer.colorize("Echo removed.", :amber)
        else
          hackr.echoes.create!(pulse: pulse)
          println renderer.colorize("Pulse echoed!", :green)
        end
      end

      def view_pulse(pulse_id)
        unless pulse_id
          println renderer.colorize("Usage: view <id>", :amber)
          return
        end

        pulse = Pulse.find_by(id: pulse_id)
        unless pulse
          println renderer.colorize("Pulse not found.", :red)
          return
        end

        println ""
        println renderer.divider("PULSE ##{pulse.id}", width: 60, color: :cyan)
        display_pulse(pulse)

        # Show thread if it has splices
        if pulse.splices.any?
          println ""
          println renderer.colorize("  Thread:", :amber)
          pulse.splices.order(pulsed_at: :asc).each do |splice|
            display_pulse(splice, indent: 1)
          end
        end

        println ""
      end

      def splice_pulse(args)
        unless authenticated?
          require_auth_message
          return
        end

        parts = args&.split(" ", 2)
        pulse_id = parts&.first&.to_i
        content = parts&.last

        if pulse_id.nil? || pulse_id.zero? || content.blank?
          println renderer.colorize("Usage: splice <id> <message>", :amber)
          return
        end

        parent = Pulse.find_by(id: pulse_id)
        unless parent
          println renderer.colorize("Pulse not found.", :red)
          return
        end

        pulse = hackr.pulses.build(content: content, parent_pulse: parent)

        if pulse.save
          println renderer.colorize("Splice posted!", :green)
        else
          println renderer.colorize("Failed: #{pulse.errors.full_messages.join(", ")}", :red)
        end
      end

      def view_user(alias_name)
        if alias_name.blank?
          println renderer.colorize("Usage: user <alias>", :amber)
          return
        end

        user = GridHackr.find_by(hackr_alias: alias_name)
        unless user
          println renderer.colorize("User not found.", :red)
          return
        end

        pulses = user.pulses.where(signal_dropped: false)
          .where(parent_pulse_id: nil)
          .order(pulsed_at: :desc)
          .limit(10)

        println ""
        println renderer.divider("@#{user.hackr_alias}", width: 60, color: :purple)
        println ""

        if pulses.empty?
          println renderer.colorize("  No pulses from this user.", :gray)
        else
          pulses.each { |p| display_pulse(p) }
        end

        println ""
      end
    end
  end
end
