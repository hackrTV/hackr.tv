# Read ack from the /uplink shell (Phase 2 item 5): the viewer watched
# `channel` down to packet `last_read_message_id`. The shell posts it,
# debounced, whenever a packet lands while the log sits at the bottom
# (and once more, keepalive, on the way out) — the page render only
# marks what was there on load. The mark is a high-water, so a stale
# ack is a no-op; the id must belong to the channel.
class Uplink::ReadsController < ApplicationController
  before_action :require_login

  # POST /uplink/reads
  def create
    channel = ChatChannel.active.find_by(slug: params[:channel])
    return head :not_found unless channel
    return head :forbidden unless channel.viewable_by?(current_hackr)

    packet = channel.chat_messages.find_by(id: params[:last_read_message_id])
    return head :unprocessable_entity unless packet

    UplinkChannelRead.mark!(current_hackr, channel, packet.id)
    head :no_content
  end
end
