# frozen_string_literal: true

module Uplink
  # Single source of truth for "may this hackr transmit on this channel
  # right now" — blackout, squelch, role access, slow mode, in that
  # order. Used by the Hotwire form flow (Uplink::PacketsController);
  # the admin send_packet API bypasses it deliberately (service
  # accounts). Error strings predate the Hotwire flow and are rendered
  # verbatim.
  class PacketGatekeeper
    Result = Struct.new(:error, :wait_seconds, :status) do
      def ok?
        error.nil?
      end
    end

    PASS = Result.new.freeze

    def self.check(hackr, channel)
      if UserPunishment.blackedout?(hackr)
        return Result.new(error: "You have been blackedout from Uplink.", status: :forbidden)
      end

      if UserPunishment.squelched?(hackr)
        return Result.new(error: "You have been squelched. Please wait for your squelch to expire.", status: :forbidden)
      end

      unless channel.accessible_by?(hackr)
        return Result.new(error: "You cannot access this channel.", status: :forbidden)
      end

      if channel.slow_mode_seconds > 0
        last_message = channel.chat_messages
          .where(grid_hackr: hackr)
          .order(created_at: :desc)
          .first

        if last_message && last_message.created_at > channel.slow_mode_seconds.seconds.ago
          wait_time = (channel.slow_mode_seconds - (Time.current - last_message.created_at)).ceil
          return Result.new(
            error: "Slow mode active. Please wait #{wait_time} seconds.",
            wait_seconds: wait_time,
            status: :too_many_requests
          )
        end
      end

      PASS
    end
  end
end
