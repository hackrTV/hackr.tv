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
  HISTORY_PACKETS = 40 # one scrollback page (GET /uplink/log?before=)

  # GET /uplink — the NODE shell (uplink/_shell): channel sidebar, channel
  # pane with the live stage on livestream channels, operatives roster.
  def show
    @channels = ChatChannel.active.ordered.to_a
    @channel = resolve_channel(@channels, default_slug: "ambient")
    return redirect_to uplink_path if channel_off_limits?

    load_packets
    @live_stream = HackrStream.includes(:artist).current_live
    @roster = Uplink::Roster.for(viewable? ? @channel : nil, viewer: current_hackr)
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
  def log
    @channel = ChatChannel.active.find_by(slug: params[:channel])
    return head :not_found unless @channel
    return head :forbidden unless @channel.viewable_by?(current_hackr)

    if params[:before].present?
      before = params[:before].to_i
      return head :bad_request unless before.positive?

      load_packets(before: before, limit: HISTORY_PACKETS)
      render partial: "uplink/packets", locals: {packets: @packets, viewer: current_hackr, more: @more_packets}
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

  # Newest `limit` active packets (older than `before` when paging),
  # chronological. Ordered by id — the scrollback cursor — so pages never
  # skip or repeat a row; one extra row is fetched to learn whether older
  # packets exist (@more_packets) without a second query.
  def load_packets(before: nil, limit: RECENT_PACKETS)
    @packets = []
    @more_packets = false
    return unless viewable?

    scope = @channel.chat_messages.active.includes(:grid_hackr)
    scope = scope.where("id < ?", before) if before
    rows = scope.order(id: :desc).limit(limit + 1).to_a
    @more_packets = rows.size > limit
    @packets = rows.first(limit).reverse
  end
end
