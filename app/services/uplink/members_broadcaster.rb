# frozen_string_literal: true

# Pushes the operatives roster (uplink/_members) to every /uplink shell
# on a channel when a presence row appears or goes. Debounced: the first
# change in a window claims a cache key and enqueues one trailing job
# (2s), later changes in the window ride that job — a stream going live
# makes hundreds of viewers join within seconds, and one render per
# channel per burst is plenty. The job clears the key before rendering,
# so a change that lands mid-render schedules the next one. The claim is
# `write(unless_exist:)`, which solid_cache runs as a locked read-then-
# write inside a transaction — serialized on our SQLite cache DB, where
# Rails opens every transaction BEGIN IMMEDIATE (on Postgres/MySQL a row
# that does not exist yet cannot be locked, so two first claimers could
# both win there: one duplicate render, nothing worse). solid_cache fails
# safe on a transient DB error (busy timeout) by returning "held", so the
# worst case on this stack is one skipped render until the next change;
# CLAIM_TTL also bounds a claim whose job never ran. Rides its
# own ["uplink_members", slug] stream so the home dock and popout, which
# hold the uplink_html stream, never receive roster HTML they can't use.
# The same render also pushes the channel's sidebar count
# (uplink/_channel_count): on that members stream to the shells on the
# channel and on the channel's bump stream (Uplink::Unread::STREAM — the
# one every shell elsewhere holds per channel in its clearance) to the
# rest. No new subscriptions, and no count for a channel you can't open.
module Uplink
  module MembersBroadcaster
    STREAM = "uplink_members"
    TARGET = "uplink-members"
    COUNT_TARGET = "uplink-count" # + "-<slug>": the sidebar row's count span
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
      roster = Roster.for(channel)
      Turbo::StreamsChannel.broadcast_replace_to(
        [STREAM, channel.slug],
        target: TARGET,
        partial: "uplink/members",
        locals: {roster: roster}
      )
      count = ApplicationController.render(partial: "uplink/channel_count", locals: {channel: channel, count: roster.members.size}).strip # the partial's trailing newline
      [[STREAM, channel.slug], [Unread::STREAM, channel.slug]].each do |stream|
        Turbo::StreamsChannel.broadcast_replace_to(stream, target: count_target(channel.slug), html: count)
      end
    end

    def self.count_target(slug)
      "#{COUNT_TARGET}-#{slug}"
    end

    def self.claim_key(channel_id)
      "uplink:members:pending:#{channel_id}"
    end
  end
end
