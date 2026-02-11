# frozen_string_literal: true

module Terminal
  module Handlers
    # Handler for Uplink real-time chat
    class UplinkHandler < BaseHandler
      RECENT_PACKET_LIMIT = 20

      def on_enter
        super
        unless authenticated?
          require_auth_message
          go_back
          return
        end

        @current_channel = nil
        @messages = []
        @last_message_at = {}

        clear_screen
        display_banner
        display_channels
        setup_realtime
        auto_join_channel
      end

      def on_leave
        session.realtime.unsubscribe_uplink
        session.realtime.clear_uplink_callback
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
        when "join", "j"
          join_channel(args)
        when "channels", "ch"
          display_channels
        when "say"
          send_message(args)
        when "history", "h"
          display_history
        when "who"
          display_who
        when "help", "?"
          display_help
        else
          # Bare text = send message
          send_message(input)
        end
      end

      def prompt
        channel_name = @current_channel&.slug || "uplink"
        renderer.colorize("##{channel_name}> ", :cyan)
      end

      def display_help
        println ""
        println renderer.header("UPLINK COMMANDS", color: :cyan)
        println ""
        println renderer.colorize("  Comms:", :amber)
        println "    <message>         - Send a message (just type)"
        println "    say <message>     - Send a message"
        println ""
        println renderer.colorize("  Channels:", :amber)
        println "    channels (ch)     - List available channels"
        println "    join <channel> (j)- Switch to a channel"
        println ""
        println renderer.colorize("  Info:", :amber)
        println "    history (h)       - Show recent messages"
        println "    who               - Show channel info"
        println ""
        println renderer.colorize("  Other:", :amber)
        println "    back              - Return to main menu"
        println "    help (?)          - Show this help"
        println ""
      end

      private

      def display_banner
        banner = Art.banner(:uplink)
        if banner.present?
          println renderer.colorize(banner, :cyan)
        end
      end

      def auto_join_channel
        channel = ChatChannel.active.order(:id).find { |ch| ch.accessible_by?(hackr) }
        if channel
          switch_to_channel(channel)
        else
          println renderer.colorize("  No channels available.", :red)
        end
      end

      def display_channels
        println ""
        println renderer.header("UPLINK CHANNELS", color: :cyan)
        println ""

        ChatChannel.active.order(:id).each do |channel|
          available = channel.accessible_by?(hackr)
          status = available ? renderer.colorize("[OPEN]", :green) : renderer.colorize("[LOCKED]", :red)
          current = (@current_channel&.id == channel.id) ? renderer.colorize(" <<", :amber) : ""
          println "  ##{channel.slug} - #{channel.name} #{status}#{current}"
          println "    #{renderer.colorize(channel.description, :gray)}" if channel.description.present?
        end

        println ""
      end

      def join_channel(slug)
        if slug.blank?
          println renderer.colorize("Usage: join <channel>", :amber)
          return
        end

        slug = slug.delete_prefix("#")
        channel = ChatChannel.find_by(slug: slug)

        unless channel
          println renderer.colorize("Channel not found: ##{slug}", :red)
          return
        end

        unless channel.accessible_by?(hackr)
          println renderer.colorize("Access denied to ##{slug}.", :red)
          return
        end

        switch_to_channel(channel)
      end

      def switch_to_channel(channel)
        return if @current_channel&.id == channel.id

        # Unsubscribe from old channel
        session.realtime.unsubscribe_uplink if @current_channel

        @current_channel = channel
        @messages = []

        # Subscribe to new channel
        session.realtime.subscribe_uplink(channel.stream_name)

        load_history
        display_history

        println renderer.colorize("  Joined ##{channel.slug}. Type a message or 'help' for commands.", :green)
        println ""
      end

      def load_history
        return unless @current_channel

        @messages = @current_channel.chat_messages
          .active
          .recent
          .limit(RECENT_PACKET_LIMIT)
          .includes(:grid_hackr)
          .reverse
      end

      def display_history
        println ""
        println renderer.divider("##{@current_channel&.slug || "uplink"}", width: 60, color: :cyan)
        println ""

        if @messages.empty?
          println renderer.colorize("  No messages yet. Be the first to transmit.", :gray)
        else
          @messages.each { |msg| display_message(msg) }
        end

        println ""
      end

      def display_message(msg)
        return if msg.dropped?

        alias_name = msg.grid_hackr&.hackr_alias || "Unknown"
        role = msg.grid_hackr&.role
        badge = role_badge(role)
        time = msg.created_at.strftime("%H:%M %Z")

        println "  #{renderer.colorize(time, :gray)} #{badge}#{renderer.colorize("@#{alias_name}", :purple)}: #{msg.content}"
      end

      def display_realtime_packet(event)
        badge = role_badge(event[:role])
        time = Time.current.strftime("%H:%M %Z")

        session.output.puts ""
        session.output.puts "  #{renderer.colorize(time, :gray)} #{badge}#{renderer.colorize("@#{event[:hackr_alias]}", :purple)}: #{event[:content]}"
        session.output.print prompt
        session.output.flush
      end

      def send_message(content)
        if content.blank?
          println renderer.colorize("Usage: say <message>", :amber)
          return
        end

        unless @current_channel
          println renderer.colorize("Join a channel first. Type 'channels' to see available channels.", :red)
          return
        end

        # Check punishments
        if UserPunishment.blackouted?(hackr)
          println renderer.colorize("You are blackouted from Uplink.", :red)
          return
        end

        if UserPunishment.squelched?(hackr)
          println renderer.colorize("You are squelched. Messages cannot be sent.", :red)
          return
        end

        # Check slow mode
        if @current_channel.slow_mode_seconds > 0
          last = @last_message_at[@current_channel.id]
          if last && (Time.current - last) < @current_channel.slow_mode_seconds
            remaining = (@current_channel.slow_mode_seconds - (Time.current - last)).ceil
            println renderer.colorize("Slow mode active. Wait #{remaining}s.", :amber)
            return
          end
        end

        # Check content length
        if content.length > 512
          println renderer.colorize("Message too long! Maximum 512 characters.", :red)
          return
        end

        message = ChatMessage.new(
          content: content,
          chat_channel: @current_channel,
          grid_hackr: hackr
        )

        if message.save
          @last_message_at[@current_channel.id] = Time.current
          @messages << message
          # Trim cached messages
          @messages.shift if @messages.size > RECENT_PACKET_LIMIT
          # Track so realtime subscriber skips this packet (sent from here)
          session.realtime.track_local_packet(message.id)
        else
          println renderer.colorize("Failed: #{message.errors.full_messages.join(", ")}", :red)
        end
      end

      def display_who
        println ""
        println renderer.header("##{@current_channel&.slug || "uplink"} INFO", color: :cyan)
        println ""

        if @current_channel
          println "  #{renderer.colorize("Channel:", :amber)} ##{@current_channel.slug}"
          println "  #{renderer.colorize("Name:", :amber)} #{@current_channel.name}"
          println "  #{renderer.colorize("Description:", :amber)} #{@current_channel.description}" if @current_channel.description.present?
          println "  #{renderer.colorize("Min. Role:", :amber)} #{@current_channel.minimum_role}"
          println "  #{renderer.colorize("Slow Mode:", :amber)} #{@current_channel.slow_mode_seconds}s" if @current_channel.slow_mode_seconds > 0
          println "  #{renderer.colorize("Messages:", :amber)} #{@current_channel.chat_messages.active.count}"
        else
          println renderer.colorize("  Not in a channel.", :gray)
        end

        println ""
      end

      def setup_realtime
        session.realtime.on_uplink do |event|
          display_realtime_packet(event)
        end
      end

      def role_badge(role)
        case role
        when "admin"
          renderer.colorize("[A] ", :red)
        when "operator"
          renderer.colorize("[O] ", :amber)
        else
          ""
        end
      end
    end
  end
end
