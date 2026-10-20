# frozen_string_literal: true

# Who is connected to a channel, for the Uplink shell's members pane.
# Source of truth is GridUplinkPresence (touched by LiveChatChannel on
# subscribe + every 60s, removed on unsubscribe, 10-minute TTL) — the
# same rows the mining economy reads. Members come back anonymized
# (Uplink::Callsign) and grouped by role; aliases are never loaded.
# Service accounts (relay/synthia bridges hold admin-token cable
# subscriptions) are excluded: they are bots, not operatives.
module Uplink
  class Roster
    Member = Struct.new(:token, :role) do
      def label
        "#{Callsign::PREFIX}-#{token}"
      end
    end

    ROLES = %w[admin operator operative].freeze

    def self.for(channel, viewer: nil)
      new(channel, viewer: viewer)
    end

    # viewer: the hackr looking at the shell. They are connected the moment
    # it renders, but their presence row only lands when the cable
    # subscribes a beat later — so they are synthesized into the roster
    # (no DB write on a GET: a blacked-out viewer never gets a row and the
    # mining economy never mistakes a page load for a connection).
    def initialize(channel, viewer: nil)
      @channel = channel
      @viewer = viewer
    end

    def members
      @members ||= load_members
    end

    def empty?
      members.empty?
    end

    # {"admin" => [Member, …], …} in ROLES order, empty groups omitted.
    def groups
      members.group_by(&:role).sort_by { |role, _| ROLES.index(role) }.to_h
    end

    private

    def load_members
      return [] unless @channel

      rows = GridUplinkPresence.valid.in_channel(@channel)
        .joins(:grid_hackr)
        .where(grid_hackrs: {service_account: false})
        .pluck("grid_hackrs.id", "grid_hackrs.role")
      rows << [@viewer.id, @viewer.role] if @viewer && !@viewer.service_account? && rows.none? { |id, _| id == @viewer.id }

      rows.map { |id, role|
        Member.new(Callsign.token(id), ROLES.include?(role) ? role : "operative")
      }.sort_by(&:token) # token order is arbitrary; alias order would leak
    end
  end
end
