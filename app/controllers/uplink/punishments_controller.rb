# Operator menu for the /uplink shell (Phase 2 item 4): inline squelch,
# blackout and lift without leaving the channel. The […] on a packet or a
# roster row loads GET …/menu into the shell's uplink-modmenu turbo-frame
# (popover Stimulus controller); its buttons POST back here and get a
# toast in reply (plus, for drop/restore, the packet replace from
# Uplink::PacketsController). /root/uplink stays the full punishments
# console; this is the fast path.
#
# The target is never a bare hackr id: a packet names its author, who is
# already public in the log, and a roster callsign is resolved over the
# live presence rows (stale token → 404) so the alias behind it never
# reaches the client — token menus and toasts speak of SIG-XXXXXX only.
# Jurisdiction: operators moderate operatives, admins moderate operators
# and operatives; nobody moderates a peer, a superior, themselves or a
# service account (the bridges). Clients hide the […] in those cases from
# the role metas; this is the check that counts.
#
# A packet's menu comes in three shapes (@mode). :moderate — a native
# author the viewer outranks: drop/restore + the punishments. :own — the
# viewer's own packet, any role: DROP PACKET (RESTORE for an operator's
# own dropped one), no punishments (nobody moderates themselves).
# :bridged — a packet by a bridge or bot service account, operator+:
# drop/restore only (the account behind a Twitch line is the bridge, not
# whoever typed it). Since 2026-10-26 the shell has no hover ×: every
# drop there goes through this menu (the dock/popout keep × ↺).
class Uplink::PunishmentsController < ApplicationController
  before_action :require_login
  before_action :require_operator, if: -> { params[:token] } # a token resolves presence rows: operators only, before any lookup
  before_action :resolve_target
  before_action :require_jurisdiction

  # Minutes the menu offers for a squelch (blank = permanent; the menu
  # only sends blank for blackouts).
  DURATIONS = {10 => "10m", 60 => "1h", 1440 => "24h"}.freeze
  TOKEN = /\A[0-9a-f]{#{Uplink::Callsign::LENGTH}}\z/i

  # GET /uplink/packets/:id/menu | GET /uplink/operatives/:token/menu
  def menu
    return redirect_to uplink_path unless turbo_frame_request?

    @active = (@mode == :moderate) ? UserPunishment.active_for(@target).order(:created_at).to_a : []
    @paths = if @packet
      {squelch: uplink_packet_squelch_path(@packet), blackout: uplink_packet_blackout_path(@packet), lift: uplink_packet_lift_path(@packet)}
    else
      {squelch: uplink_operative_squelch_path(@token), blackout: uplink_operative_blackout_path(@token), lift: uplink_operative_lift_path(@token)}
    end
  end

  # POST …/squelch (duration_minutes, reason)
  def squelch
    punish("squelch")
  end

  # POST …/blackout (duration_minutes, reason)
  def blackout
    punish("blackout")
  end

  # POST …/lift — every active punishment of the target, each logged.
  def lift
    active = UserPunishment.active_for(@target).to_a
    return refuse(:unprocessable_entity, "#{@label} has no active punishment.") if active.empty?

    active.each { |punishment| punishment.lift!(current_hackr) }
    toast("#{@label} lifted: #{active.map { |p| past(p.punishment_type) }.uniq.join(" + ")}.")
  end

  private

  def require_operator
    head :forbidden unless current_hackr.at_least_operator?
  end

  def resolve_target
    if params[:token]
      @token = params[:token].downcase
      @label = "#{Uplink::Callsign::PREFIX}-#{@token.upcase}"
      @target = resolve_token(@token)
      @mode = :moderate
      refuse(:not_found, "#{@label} is no longer connected.") unless @target
    else
      @packet = ChatMessage.find_by(id: params[:id])
      return refuse(:not_found, "That packet is gone.") unless @packet

      @target = @packet.grid_hackr
      @mode = if @target.id == current_hackr.id
        :own
      elsif @target.service_account?
        :bridged
      else
        :moderate
      end
      # A bridged packet is named by its bridged sender ("TTV viewer"),
      # never by the bridge account's alias.
      @label = (@mode == :bridged) ? helpers.uplink_packet_sender(@packet) : "@#{@target.hackr_alias}"
    end
  end

  # :moderate needs an operator with the target in jurisdiction, for the
  # menu and every action. :own and :bridged open the menu only — their
  # items are the packet endpoints (Uplink::PacketsController) — so a
  # squelch/blackout/lift aimed at oneself or a bridge is refused here.
  def require_jurisdiction
    allowed = case @mode
    when :own then action_name == "menu"
    when :bridged then action_name == "menu" && current_hackr.at_least_operator?
    else current_hackr.at_least_operator? && moderatable?(@target)
    end
    refuse(:forbidden, "#{@label} is outside your clearance.") unless allowed
  end

  def moderatable?(target)
    !target.service_account? && target.role_level < current_hackr.role_level
  end

  # Presence rows are the only place a callsign resolves from, and only
  # while the hackr is connected — the same rows the roster renders.
  # Searched across channels: the token is stable, and the roster the
  # operator read it from may be a channel switch behind.
  def resolve_token(token)
    return nil unless token.match?(TOKEN)

    wanted = token.upcase
    id = GridUplinkPresence.valid.distinct.pluck(:grid_hackr_id).find { |i| Uplink::Callsign.token(i) == wanted }
    id && GridHackr.find_by(id: id)
  end

  def punish(type)
    duration = params[:duration_minutes].presence&.to_i
    return refuse(:unprocessable_entity, "Pick a duration from the menu.") if duration && !DURATIONS.key?(duration)
    return refuse(:unprocessable_entity, "#{@label} is already #{past(type)}.") if UserPunishment.active_for(@target, type).exists?

    UserPunishment.public_send(:"#{type}!", @target, issued_by: current_hackr, duration_minutes: duration, reason: params[:reason].presence)
    toast("#{@label} #{past(type)} #{duration ? "for #{DURATIONS[duration]}" : "permanently"}.")
  end

  def past(type)
    (type == "squelch") ? "squelched" : "blacked out"
  end

  # The menu GET always answers with the frame — Turbo visits a frameless
  # error body as a page — so a miss renders the menu's empty state.
  # Actions answer with an error toast (the UI that sent them is stale).
  def refuse(status, message)
    if action_name == "menu"
      @error = message
      render :menu, status: status
    else
      toast(message, status: status)
    end
  end

  def toast(message, status: :ok)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("toast-region", partial: "shared/toast_moderation",
          locals: {message: message, error: status != :ok}), status: status
      end
      format.html { redirect_back fallback_location: uplink_path, flash: {(status == :ok) ? :success : :error => message} }
    end
  end
end
