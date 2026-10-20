# frozen_string_literal: true

# Pushes the operatives roster (uplink/_members) to every /uplink shell
# on a channel when a presence row appears or goes. Debounced: the first
# change in a window claims a cache key and enqueues one trailing job
# (2s), later changes in the window ride that job — a stream going live
# makes hundreds of viewers join within seconds, and one render per
# channel per burst is plenty. The job clears the key before rendering,
# so a change that lands mid-render schedules the next one. Rides its
# own ["uplink_members", slug] stream so the home dock and popout, which
# hold the uplink_html stream, never receive roster HTML they can't use.
module Uplink
  module MembersBroadcaster
    STREAM = "uplink_members"
    TARGET = "uplink-members"
    DEBOUNCE = 2.seconds
    CLAIM_TTL = 10.seconds

    def self.schedule(channel_id)
      return unless Rails.cache.write(claim_key(channel_id), 1, unless_exist: true, expires_in: CLAIM_TTL)

      MembersBroadcastJob.set(wait: DEBOUNCE).perform_later(channel_id)
    end

    def self.release(channel_id)
      Rails.cache.delete(claim_key(channel_id))
    end

    def self.broadcast(channel)
      Turbo::StreamsChannel.broadcast_replace_to(
        [STREAM, channel.slug],
        target: TARGET,
        partial: "uplink/members",
        locals: {roster: Roster.for(channel)}
      )
    end

    def self.claim_key(channel_id)
      "uplink:members:pending:#{channel_id}"
    end
  end
end
