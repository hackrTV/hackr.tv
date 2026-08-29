# Server-rendered home page (Hotwire migration Phase 3) — ports
# HomePage.tsx. Stream state renders at page load; the stream-status
# Stimulus controller refreshes the page on go-live/end broadcasts, and
# stream-watch ports the watch-time heartbeat subscription.
class HomeController < ApplicationController
  layout "hotwire"

  def show
    @live = HackrStream.current_live
    @next_scheduled = HackrStream.next_scheduled
    return unless @live

    # Docked Uplink chat (Phase 5): the live embed's side panel embeds
    # the livestream channel with its recent packets.
    @uplink_channel = ChatChannel.livestream_default
    @uplink_packets = if @uplink_channel
      @uplink_channel.chat_messages.active.recent
        .limit(UplinkController::RECENT_PACKETS).includes(:grid_hackr).reverse
    else
      []
    end
  end
end
