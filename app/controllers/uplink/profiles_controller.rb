# Operative record card for the /uplink shell (Phase 2 item 3). Clicking
# a packet author loads GET /uplink/profiles/:alias into the shell's
# uplink-popover turbo-frame (popover Stimulus controller); the response
# is the compact WIRE profile header — alias, role, clearance, member
# since, last active, bio, stat tiles, link to the full profile. Login
# required like the shell; the lookup mirrors WireController#profile
# (case-insensitive alias; URLs are generated lowercase because the
# LowercaseRedirect middleware 301s mixed-case paths). Outside a frame
# (a pasted URL) the card has no home, so the request goes to the WIRE
# profile instead.
class Uplink::ProfilesController < ApplicationController
  before_action :require_login

  # GET /uplink/profiles/:alias
  def show
    return redirect_to wire_user_path(params[:alias].downcase) unless turbo_frame_request?

    @hackr = GridHackr.where("LOWER(hackr_alias) = ?", params[:alias].downcase).first
    return render :not_found, status: :not_found unless @hackr

    @stats = Grid::ProfileStats.for(@hackr)
  end
end
