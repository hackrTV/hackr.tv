# Uplink reactions (Phase 2 item 7). A packet's hover :) loads the emote
# picker (GET …/reactions) into the shell's uplink-reactmenu turbo-frame
# (popover Stimulus controller, as the record card, the operator menu and
# the pins panel); a pick, or a click on an existing chip, toggles the
# viewer's reaction (POST …/reactions, emote_slug). Anyone who can read
# the channel may react, blackout/squelch excepted — no posting-role or
# slow-mode gate: reacting is lighter than transmitting (an announcement
# channel's readers react, as on Discord). The model broadcasts the chip
# row to everyone; the reply replaces it for the viewer right away.
class Uplink::ReactionsController < ApplicationController
  before_action :require_login
  before_action :set_packet

  # GET /uplink/packets/:id/reactions — the picker, frame only (a pasted
  # URL goes to the channel). Every chat-ready emote, the viewer's own
  # reactions marked so a second pick reads as "remove".
  def menu
    return redirect_to uplink_path(channel: @packet&.chat_channel&.slug) unless turbo_frame_request?
    return refuse_menu(:not_found, "That packet is gone.") unless @packet && !@packet.dropped?
    return refuse_menu(:forbidden, "#{@packet.chat_channel.name} is outside your clearance.") unless viewable?

    @emotes = Emote.render_map
    @mine = @packet.reactions.where(grid_hackr: current_hackr).pluck(:emote_slug)
  end

  # POST /uplink/packets/:id/reactions — toggle. Removing is always
  # allowed (an emote that has since been disabled still comes off);
  # adding needs a chat-ready emote and room under REACTION_CAP distinct
  # emotes on the packet. A lost race on the unique index is the same
  # quiet success as a stale row.
  def toggle
    return head :not_found unless @packet
    return refuse(:forbidden, "#{@packet.chat_channel.name} is outside your clearance.") unless viewable?
    return refuse(:forbidden, "You have been blackedout from Uplink.") if UserPunishment.blackedout?(current_hackr)
    return refuse(:forbidden, "You have been squelched. Please wait for your squelch to expire.") if UserPunishment.squelched?(current_hackr)
    return refuse(:unprocessable_entity, "Cannot react to a dropped packet.") if @packet.dropped?

    slug = params[:emote_slug].to_s
    existing = @packet.reactions.find_by(grid_hackr: current_hackr, emote_slug: slug)
    if existing
      existing.destroy
    else
      return refuse(:unprocessable_entity, "Unknown emote.") unless Emote.render_map.key?(slug)

      slugs = @packet.reactions.distinct.pluck(:emote_slug)
      if slugs.exclude?(slug) && slugs.size >= ChatMessage::REACTION_CAP
        return refuse(:unprocessable_entity, "This packet already has #{helpers.pluralize(ChatMessage::REACTION_CAP, "reaction")}.")
      end

      begin
        @packet.reactions.create!(grid_hackr: current_hackr, emote_slug: slug)
      rescue ActiveRecord::RecordNotUnique
        nil
      end
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(helpers.dom_id(@packet, :reactions),
          partial: "uplink/reactions", locals: {packet: @packet})
      end
      format.html { redirect_back fallback_location: uplink_path(channel: @packet.chat_channel.slug) }
    end
  end

  private

  def set_packet
    @packet = ChatMessage.find_by(id: params[:id])
  end

  def viewable?
    @packet.chat_channel.viewable_by?(current_hackr)
  end

  # Always the frame — Turbo visits a frameless error body as a page.
  def refuse_menu(status, message)
    @error = message
    render :menu, status: status
  end

  # An error toast at the real status, as the operator menu's refusals.
  def refuse(status, message)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("toast-region", partial: "shared/toast_moderation",
          locals: {message: message, error: true, kicker: "REACTIONS"}), status: status
      end
      format.html { redirect_back fallback_location: uplink_path, flash: {error: message} }
    end
  end
end
