# Packet compose + moderation for the Hotwire uplink pages (Phase 5).
# Mirrors Api::Uplink::PacketsController; the model broadcasts handle the
# live log updates for every subscriber (dual-publish). JSON stays on the
# API controller for external consumers.
class Uplink::PacketsController < ApplicationController
  layout "hotwire"

  before_action :require_login
  before_action :set_packet, only: %i[drop restore]

  # POST /uplink/packets
  def create
    @channel = ChatChannel.find_by(slug: params[:channel_slug])
    return head :not_found unless @channel

    gate = Uplink::PacketGatekeeper.check(current_hackr, @channel)
    unless gate.ok?
      return render_form_error(gate.error, wait_seconds: gate.wait_seconds, status: gate.status)
    end

    hackr_stream = @channel.requires_livestream ? HackrStream.current_live : nil
    @packet = @channel.chat_messages.build(
      grid_hackr: current_hackr,
      hackr_stream: hackr_stream,
      content: params[:content]
    )

    if @packet.save
      # Same trigger site as the API create.
      Grid::AchievementChecker.new(current_hackr).check("uplink_packets_count")
      respond_to do |format|
        format.turbo_stream # append own contextual packet + clear the error slot
        format.html { redirect_to uplink_path(channel: @channel.slug) }
      end
    else
      error = @packet.errors[:content].first || @packet.errors.full_messages.join(", ")
      render_form_error(error, status: :unprocessable_entity)
    end
  end

  # POST /uplink/packets/:id/drop — operator+, or the packet's author
  # (require_operator_or_owner parity with the API destroy).
  def drop
    unless current_hackr.at_least_operator? || @packet.grid_hackr_id == current_hackr.id
      return head :forbidden
    end

    if @packet.drop!
      ModerationLog.log_action(
        actor: current_hackr,
        action: "drop_packet",
        chat_message: @packet,
        target: @packet.grid_hackr
      )
    end

    replace_packet
  end

  # POST /uplink/packets/:id/restore — operator+ only (moderation undo;
  # the SPA had no user-facing restore).
  def restore
    return head :forbidden unless current_hackr.at_least_operator?

    if @packet.restore!
      ModerationLog.log_action(
        actor: current_hackr,
        action: "restore_packet",
        chat_message: @packet,
        target: @packet.grid_hackr
      )
    end

    replace_packet
  end

  private

  def set_packet
    @packet = ChatMessage.find_by(id: params[:id])
    head :not_found unless @packet
  end

  # Immediate feedback for the acting viewer; everyone else gets the
  # model's broadcast replace (idempotent by dom_id).
  def replace_packet
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          helpers.dom_id(@packet),
          partial: "uplink/packet",
          locals: {packet: @packet, viewer: current_hackr}
        )
      end
      format.html { redirect_back fallback_location: uplink_path }
    end
  end

  def render_form_error(error, status:, wait_seconds: nil)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("uplink-form-error",
          partial: "uplink/form_error",
          locals: {error: error, wait_seconds: wait_seconds}), status: status
      end
      format.html { redirect_back fallback_location: uplink_path, flash: {error: error} }
    end
  end
end
