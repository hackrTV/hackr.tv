# Server-rendered Uplink chat (Hotwire migration Phase 5) — ports
# UplinkPage.tsx / UplinkPopoutPage.tsx. The log is rendered with the
# recent packets (the SPA's initial_packets merge); live inserts arrive
# over Turbo Streams from ChatMessage's dual-publish broadcasts. The
# uplink Stimulus controller additionally holds a LiveChatChannel
# subscription purely for presence counts + connection state (packets on
# that JSON channel are ignored — relay/synthia stay its real consumers).
class UplinkController < ApplicationController
  before_action :require_login, only: [:show]

  RECENT_PACKETS = 20 # LiveChatChannel#send_recent_packets parity

  # GET /uplink
  def show
    @channels = ChatChannel.active.order(:id).to_a
    @channel = resolve_channel(@channels, default_slug: "ambient")
    return redirect_to uplink_path if channel_off_limits?

    load_packets
  end

  # GET /uplink/popout — public (livestream viewing), slim layout,
  # livestream channels only (UplinkPopoutPage livestreamOnly parity).
  def popout
    @channels = ChatChannel.active.requiring_livestream.order(:id).to_a
    @channel = resolve_channel(@channels, default_slug: ChatChannel.livestream_default&.slug)
    return redirect_to uplink_popout_path if channel_off_limits?

    load_packets
    render layout: "uplink_popout"
  end

  # GET /uplink/log — reconnect recovery: the uplink Stimulus controller
  # reloads the log frame after a cable reconnect so packets broadcast
  # during the gap aren't lost (the SPA re-merged initial_packets).
  def log
    @channel = ChatChannel.active.find_by(slug: params[:channel])
    return head :not_found unless @channel
    return head :forbidden unless @channel.viewable_by?(current_hackr)

    load_packets
    render layout: false
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

  def load_packets
    @packets = if @channel&.viewable_by?(current_hackr)
      @channel.chat_messages.active.recent.limit(RECENT_PACKETS).includes(:grid_hackr).reverse
    else
      []
    end
  end
end
