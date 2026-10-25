# frozen_string_literal: true

# Per-channel unread counts for the /uplink sidebar (Phase 2 item 5).
# `sync` runs once per shell render: it seeds a caught-up mark for every
# viewable channel the hackr has never had one for (a first visit must
# not show every channel at 99+), marks the channel on screen at its
# newest packet, then counts the active packets above each mark in one
# grouped query — and, in a second one, those among them that @mention
# the viewer (a LIKE on the alias: a prefix false positive only recolors
# the badge; the toast itself resolves mentions exactly). The channel
# on screen is left out of the result (its badge never shows). Live
# updates ride the [STREAM, slug] bump stream (ChatMessage#broadcast_bump
# → the shell increments the badge); the ack endpoint
# (Uplink::ReadsController) moves the mark while the viewer watches.
module Uplink
  class Unread
    STREAM = "uplink_bump"
    CAP = 99 # display cap: "99+"

    Entry = Struct.new(:count, :mentioned) do
      def any? = count.positive?

      def label = Unread.label(count)
    end

    def self.label(count)
      (count > CAP) ? "#{CAP}+" : count.to_s
    end

    def self.bump_target(slug)
      "uplink-bump-#{slug}"
    end

    # channels: the ChatChannels the hackr may read; reading: the one on
    # screen (nil when the page shows none). Returns {channel id => Entry}
    # for every channel but `reading`.
    def self.sync(hackr, channels, reading: nil)
      new(hackr, channels, reading).sync
    end

    def initialize(hackr, channels, reading)
      @hackr = hackr
      @channels = channels
      @reading = reading
    end

    def sync
      ids = @channels.map(&:id)
      return {} if ids.empty?

      newest = ChatMessage.where(chat_channel_id: ids).group(:chat_channel_id).maximum(:id)
      marked = UplinkChannelRead.where(grid_hackr: @hackr, chat_channel_id: ids).pluck(:chat_channel_id)
      UplinkChannelRead.seed!(@hackr, (ids - marked).index_with { |id| newest[id] || 0 })
      UplinkChannelRead.mark!(@hackr, @reading, newest[@reading.id] || 0) if @reading && ids.include?(@reading.id)

      counted = ids - [@reading&.id]
      return {} if counted.empty?

      above = ChatMessage.active.where(chat_channel_id: counted).where(ABOVE_MARK_SQL, @hackr.id)
      counts = above.group(:chat_channel_id).count
      mentions = above.where.not(grid_hackr_id: @hackr.id)
        .where("chat_messages.content LIKE ? ESCAPE '\\'", "%@#{ChatMessage.sanitize_sql_like(@hackr.hackr_alias)}%")
        .group(:chat_channel_id).count
      counted.index_with { |id| Entry.new(counts[id].to_i, mentions[id].to_i.positive?) }
    end

    ABOVE_MARK_SQL = <<~SQL.squish
      chat_messages.id > COALESCE((
        SELECT r.last_read_message_id FROM uplink_channel_reads r
        WHERE r.grid_hackr_id = ? AND r.chat_channel_id = chat_messages.chat_channel_id
      ), 0)
    SQL
    private_constant :ABOVE_MARK_SQL
  end
end
