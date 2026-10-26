# The operatives roster on its own (deferred shell UX, 2026-10-26). The
# /uplink shell renders the roster inside the uplink-members-frame; the
# uplink Stimulus controller refetches it here after a cable reconnect —
# the way it reloads the log — so presence rows that came or went while
# the socket was down (broadcast on ["uplink_members", slug] to nobody)
# are recovered. Login + the channel in view, as the log; a miss renders
# the frame with an empty roster at the real status (a roster you can't
# see is no roster); outside a frame (a pasted URL) the request goes to
# the channel itself.
class Uplink::MembersController < ApplicationController
  before_action :require_login

  # GET /uplink/members?channel=
  def show
    return redirect_to uplink_path(channel: params[:channel].presence) unless turbo_frame_request?

    @channel = ChatChannel.active.find_by(slug: params[:channel])
    status = roster_status
    @roster = Uplink::Roster.for(((status == :ok) ? @channel : nil), viewer: current_hackr)
    render :show, status: status
  end

  private

  def roster_status
    return :not_found unless @channel
    return :forbidden unless @channel.viewable_by?(current_hackr)

    :ok
  end
end
