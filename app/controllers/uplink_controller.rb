# Server-rendered Uplink chat (Hotwire migration Phase 5; Discord-shaped
# shell on /uplink since 2026-10) — ports UplinkPage.tsx / UplinkPopoutPage.tsx. The log is rendered with the
# recent packets (the SPA's initial_packets merge); live inserts arrive
# over Turbo Streams from ChatMessage's dual-publish broadcasts. The
# uplink Stimulus controller additionally holds a LiveChatChannel
# subscription purely for presence counts + connection state (packets on
# that JSON channel are ignored — relay/synthia stay its real consumers).
class UplinkController < ApplicationController
  before_action :require_login, only: [:show]

  RECENT_PACKETS = 20 # LiveChatChannel#send_recent_packets parity
  HISTORY_PACKETS = 40 # one scrollback page (GET /uplink/log?before= | after=)
  AROUND_PACKETS = 20 # either side of a located packet (GET /uplink?around=)
  UNSEEN_PACKETS = 100 # the shell opens at the NEW PACKETS line when this many or fewer are unseen
  UNSEEN_CONTEXT = 5 # seen packets kept above the line for context

  # GET /uplink — the NODE shell (uplink/_shell): channel sidebar, channel
  # pane with the live stage on livestream channels, operatives roster.
  # ?around=<id> (a search hit or a pin beyond the loaded history) opens
  # the log on that packet instead of the newest ones — the page then
  # scrolls forward to the present page by page (GET /uplink/log?after=)
  # — and ?q= opens the pane's search face on that query (a hit's link
  # carries both, so the results survive the visit).
  def show
    @channels = ChatChannel.active.ordered.to_a
    @channel = resolve_channel(@channels, default_slug: "ambient")
    return redirect_to uplink_path if channel_off_limits?

    @search_query = Uplink::SearchController.normalize(params[:q])
    if params[:around].present?
      # Not an active packet of this channel: the plain page, search kept.
      return redirect_to uplink_path(channel: @channel&.slug, q: @search_query.presence) unless load_packets_around(params[:around].to_i)
    else
      @unseen_from = read_mark # the viewer's old mark: read before Uplink::Unread.sync moves it
      load_packets_for_viewer
      @unseen_divider = unseen_divider?(@unseen_from)
    end
    @live_stream = HackrStream.includes(:artist).current_live
    @roster = Uplink::Roster.for(viewable? ? @channel : nil, viewer: current_hackr)
    viewable_channels = @channels.select { |c| c.viewable_by?(current_hackr) }
    # Marks this channel read at its newest packet, seeds caught-up marks
    # for channels the viewer never saw, counts the rest for the sidebar.
    @unread = Uplink::Unread.sync(current_hackr, viewable_channels, reading: viewable? ? @channel : nil)
    # Connected counts for the sidebar rows (viewable channels only; the
    # viewer counts on this channel before their presence row lands).
    @counts = Uplink::Roster.counts(viewable_channels, viewer: current_hackr, viewing: viewable? ? @channel : nil)
  end

  # GET /uplink/popout — public (livestream viewing), slim layout,
  # livestream channels only (UplinkPopoutPage livestreamOnly parity).
  def popout
    @channels = ChatChannel.active.requiring_livestream.ordered.to_a
    @channel = resolve_channel(@channels, default_slug: ChatChannel.livestream_default&.slug)
    return redirect_to uplink_popout_path if channel_off_limits?

    load_packets
    render layout: "uplink_popout"
  end

  # GET /uplink/log — two jobs on one route:
  #   * no `before`: reconnect recovery. The uplink Stimulus controller
  #     reloads the whole log frame after a cable reconnect so packets
  #     broadcast during the gap aren't lost (the SPA re-merged
  #     initial_packets). `shell=1` (the /uplink shell's reload URL)
  #     keeps the frame in shell mode — grouping on, scrollback sentinel.
  #   * `before=<id>`: scrollback. Packets only (uplink/_packets), the
  #     HISTORY_PACKETS older than that id, chronological, plus an end
  #     marker when the channel's beginning was reached; the packet-log
  #     controller splices them in above the first packet.
  #   * `after=<id>`: the mirror for a located log (show's around= mode):
  #     the HISTORY_PACKETS newer than that id, chronological, plus the
  #     end marker once the newest packet is among them; spliced in above
  #     the bottom sentinel.
  def log
    @channel = ChatChannel.active.find_by(slug: params[:channel])
    return head :not_found unless @channel
    return head :forbidden unless @channel.viewable_by?(current_hackr)

    if params[:before].present?
      before = params[:before].to_i
      return head :bad_request unless before.positive?

      load_packets(before: before, limit: HISTORY_PACKETS)
      mark = params[:unseen_from].presence&.to_i # the shell's sentinel passes the viewer's old mark along
      locals = {packets: @packets, viewer: current_hackr, more: @more_packets, unseen_from: mark, unseen_divider: unseen_divider?(mark)}
      render partial: "uplink/packets", locals: locals
    elsif params[:after].present?
      after = params[:after].to_i
      return head :bad_request unless after.positive?

      load_packets_after(after)
      render partial: "uplink/packets", locals: {packets: @packets, viewer: current_hackr, more: @more_after}
    else
      @shell = params[:shell].present?
      load_packets
      render layout: false
    end
  end

  private

  def resolve_channel(channels, default_slug:)
    requested = channels.find { |c| c.slug == params[:channel] }
    requested || channels.find { |c| c.slug == default_slug } || channels.first
  end

  # Livestream channels render their own "only available during
  # livestreams" panel state; anything else the viewer can't see (role
  # gate) bounces back to the default channel.
  def channel_off_limits?
    return false unless @channel
    return false if @channel.requires_livestream? && !@channel.currently_available?
    return false if @channel.viewable_by?(current_hackr)

    params[:channel].present?
  end

  def viewable?
    return @viewable if defined?(@viewable)

    @viewable = @channel.present? && @channel.viewable_by?(current_hackr)
  end

  # The viewer's read mark for this channel (nil on a first sight).
  def read_mark
    return unless viewable?

    UplinkChannelRead.where(grid_hackr: current_hackr, chat_channel: @channel).pick(:last_read_message_id)
  end

  # The shell's first page: the newest RECENT_PACKETS — unless more than
  # that and at most UNSEEN_PACKETS are unseen, in which case the page
  # starts UNSEEN_CONTEXT seen packets before the mark and runs through
  # every unseen one, so the log opens at the "// NEW PACKETS //" line
  # (uplink/_log_frame; the packet-log controller scrolls to it). A flood
  # beyond the cap opens at the newest; the line is drawn by whichever
  # scrollback page holds the boundary.
  def load_packets_for_viewer
    unseen = @unseen_from ? @channel.chat_messages.active.where("id > ?", @unseen_from).count : 0
    return load_packets unless unseen.between?(RECENT_PACKETS + 1, UNSEEN_PACKETS)

    scope = @channel.chat_messages.active.includes(:grid_hackr, :reactions, reply_to: :grid_hackr)
    context = scope.where("id <= ?", @unseen_from).order(id: :desc).limit(UNSEEN_CONTEXT + 1).to_a
    @more_packets = context.size > UNSEEN_CONTEXT
    @packets = context.first(UNSEEN_CONTEXT).reverse + scope.where("id > ?", @unseen_from).order(id: :asc).to_a
  end

  # Does this page hold the boundary the line marks? A packet above the
  # mark preceded by one at or below it — or the channel's first packet
  # with everything unseen. false with no mark (first sight), nothing
  # unseen here, or a boundary further up (a scrollback page draws it).
  def unseen_divider?(mark)
    return false if mark.nil? || @packets.empty? || @packets.last.id <= mark

    @packets.first.id <= mark || !@more_packets
  end

  # A located log (GET /uplink?around=): the packet with AROUND_PACKETS
  # active ones either side, the top sentinel seeded as usual and the
  # bottom one when newer packets remain. No NEW PACKETS line — the
  # viewer asked for a place, not for what they missed. false when the
  # id is not an active packet of this channel.
  def load_packets_around(id)
    return false unless viewable? && id.positive?

    scope = @channel.chat_messages.active.includes(:grid_hackr, :reactions, reply_to: :grid_hackr)
    target = scope.find_by(id: id)
    return false unless target

    older = scope.where("id < ?", id).order(id: :desc).limit(AROUND_PACKETS + 1).to_a
    newer = scope.where("id > ?", id).order(id: :asc).limit(AROUND_PACKETS + 1).to_a
    @more_packets = older.size > AROUND_PACKETS
    @more_after = newer.size > AROUND_PACKETS
    @packets = older.first(AROUND_PACKETS).reverse + [target] + newer.first(AROUND_PACKETS)
    @focus = target.id
    true
  end

  # The `limit` active packets newer than `after`, chronological, for the
  # bottom sentinel; one extra row says whether newer ones remain.
  def load_packets_after(after, limit: HISTORY_PACKETS)
    @packets = []
    @more_after = false
    return unless viewable?

    rows = @channel.chat_messages.active.includes(:grid_hackr, :reactions, reply_to: :grid_hackr)
      .where("id > ?", after).order(id: :asc).limit(limit + 1).to_a
    @more_after = rows.size > limit
    @packets = rows.first(limit)
  end

  # Newest `limit` active packets (older than `before` when paging),
  # chronological. Ordered by id — the scrollback cursor — so pages never
  # skip or repeat a row; one extra row is fetched to learn whether older
  # packets exist (@more_packets) without a second query.
  def load_packets(before: nil, limit: RECENT_PACKETS)
    @packets = []
    @more_packets = false
    return unless viewable?

    scope = @channel.chat_messages.active.includes(:grid_hackr, :reactions, reply_to: :grid_hackr)
    scope = scope.where("id < ?", before) if before
    rows = scope.order(id: :desc).limit(limit + 1).to_a
    @more_packets = rows.size > limit
    @packets = rows.first(limit).reverse
  end
end
