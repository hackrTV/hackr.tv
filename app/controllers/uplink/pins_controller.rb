# Pinned packets panel for the /uplink shell (Phase 2 item 6). The header's
# [◆] button loads GET /uplink/pins?channel= into the shell's uplink-pins
# turbo-frame (popover Stimulus controller, as the record card and the
# operator menu): the channel's pinned, still-active packets, newest pin
# first, each a jump to its row when that row is in the loaded log, plus
# UNPIN for operators. Pinning itself is Uplink::PacketsController#pin /
# #unpin (the ◆ hover control on a packet). Login + the channel in view,
# as the log; outside a frame (a pasted URL) the request goes to the
# channel itself.
class Uplink::PinsController < ApplicationController
  before_action :require_login

  # GET /uplink/pins?channel=
  def show
    return redirect_to uplink_path(channel: params[:channel].presence) unless turbo_frame_request?

    @channel = ChatChannel.active.find_by(slug: params[:channel])
    return refuse(:not_found, "That channel is gone.") unless @channel

    refuse(:forbidden, "#{@channel.name} is outside your clearance.") unless @channel.viewable_by?(current_hackr)
  end

  private

  # Always the frame — Turbo visits a frameless error body as a page — so a
  # miss renders the panel's empty state at the real status.
  def refuse(status, message)
    @error = message
    render :show, status: status
  end
end
