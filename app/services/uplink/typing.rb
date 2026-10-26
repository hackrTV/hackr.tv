# frozen_string_literal: true

# Who is composing in an Uplink channel right now (Phase 2 item 8), by
# alias — the name about to land on the packet (XERAEN's call; the
# roster stays anonymized, typing is not lurking). The shell composer
# reports over its LiveChatChannel subscription (`typing` at most every
# THROTTLE seconds while the field has text, `stop_typing` on send, blur
# or an emptied field; the dock/popout never send) and every touch or
# stop re-broadcasts the channel's alias list on its own
# ["uplink_typing", slug] Turbo stream, replacing the line above the
# shell composer (the dock/popout hold only uplink_html, so no typing
# HTML reaches them). The line's text renders client-side (typing
# controller) so the viewer's own alias drops out of it. State is
# in-process — a hash under a mutex, like LiveChatChannel's presence
# counts; multi-process drift accepted. An alias lives TTL seconds past
# its last touch and is pruned on the next touch/stop in that channel,
# while the client clears its line TTL after the last broadcast, so a
# typer who vanishes mid-word (a closed tab) fades without a server
# timer; unsubscribe stops explicitly.
module Uplink
  module Typing
    STREAM = "uplink_typing"
    TARGET = "uplink-typing"
    TTL = 5 # seconds a touch keeps an alias in the line (the client clears on the same clock)
    THROTTLE = 3 # seconds between touches from one composer (client-side)

    @lock = Mutex.new
    @channels = Hash.new { |hash, slug| hash[slug] = {} }

    class << self
      # The hackr is composing: refresh their alias, tell the channel.
      def touch(channel, hackr)
        aliases = @lock.synchronize do
          prune(channel.slug)
          @channels[channel.slug][hackr.hackr_alias] = Time.current.to_f + TTL
          @channels[channel.slug].keys
        end
        broadcast(channel, aliases)
        aliases
      end

      # The hackr stopped (send, blur, cleared field, unsubscribe): drop
      # their alias; the channel hears about it only if it was there.
      def stop(channel, hackr)
        changed, aliases = @lock.synchronize do
          prune(channel.slug)
          removed = @channels[channel.slug].delete(hackr.hackr_alias)
          [!removed.nil?, @channels[channel.slug].keys]
        end
        broadcast(channel, aliases) if changed
        aliases
      end

      # Live aliases for a channel (the shell's first paint).
      def aliases(channel)
        @lock.synchronize do
          prune(channel.slug)
          @channels[channel.slug].keys
        end
      end

      def reset!
        @lock.synchronize { @channels.clear }
      end

      private

      def prune(slug)
        now = Time.current.to_f
        @channels[slug].delete_if { |_alias, expires_at| expires_at <= now }
        @channels.delete(slug) if @channels[slug].empty?
      end

      def broadcast(channel, aliases)
        Turbo::StreamsChannel.broadcast_replace_to(
          [STREAM, channel.slug],
          target: TARGET,
          partial: "uplink/typing",
          locals: {aliases: aliases}
        )
      end
    end
  end
end
