class Admin::UplinkController < Admin::ApplicationController
  before_action :set_channel, only: %i[edit_channel update_channel]
  before_action :set_punishment, only: [:lift_punishment]

  # GET /root/uplink
  def index
    @channels = ChatChannel.all
    @active_punishments = UserPunishment.active.includes(:grid_hackr, :issued_by)
    @recent_packets = ChatMessage.recent.limit(20).includes(:grid_hackr, :chat_channel)
    @moderation_logs = ModerationLog.recent.limit(10).includes(:actor, :target)
  end

  # GET /root/uplink/channels/:slug/edit
  def edit_channel
  end

  # PATCH /root/uplink/channels/:slug
  def update_channel
    if @channel.update(channel_params)
      set_flash_success("Channel #{@channel.name} updated successfully.")
      redirect_to admin_uplink_index_path
    else
      set_flash_error("Failed to update channel: #{@channel.errors.full_messages.join(", ")}")
      render :edit_channel
    end
  end

  # GET /root/uplink/packets
  def packets
    @packets = ChatMessage.includes(:grid_hackr, :chat_channel).recent

    # Filter by channel
    if params[:channel].present?
      @packets = @packets.joins(:chat_channel).where(chat_channels: {slug: params[:channel]})
    end

    # Filter by user
    if params[:username].present?
      hackr = GridHackr.find_by(hackr_alias: params[:username])
      @packets = hackr ? @packets.where(grid_hackr: hackr) : @packets.none
    end

    # Filter by status
    case params[:status]
    when "dropped"
      @packets = @packets.dropped
    when "active"
      @packets = @packets.active
    end

    # Search content
    if params[:search].present?
      @packets = @packets.where("content LIKE ?", "%#{params[:search]}%")
    end
  end

  # DELETE /root/uplink/packets/:id
  def destroy_packet
    @packet = ChatMessage.find(params[:id])
    hackr_alias = @packet.grid_hackr.hackr_alias

    if @packet.destroy
      set_flash_success("Packet by @#{hackr_alias} deleted.")
    else
      set_flash_error("Failed to delete packet.")
    end

    redirect_back(fallback_location: packets_admin_uplink_index_path)
  end

  # POST /root/uplink/packets/:id/drop
  def drop_packet
    @packet = ChatMessage.find(params[:id])

    if @packet.drop!
      ModerationLog.log_action(
        actor: current_hackr,
        action: "drop_packet",
        chat_message: @packet,
        target: @packet.grid_hackr
      )
      set_flash_success("Packet by @#{@packet.grid_hackr.hackr_alias} dropped.")
    else
      set_flash_error("Failed to drop packet.")
    end

    redirect_back(fallback_location: packets_admin_uplink_index_path)
  end

  # POST /root/uplink/packets/:id/restore
  def restore_packet
    @packet = ChatMessage.find(params[:id])

    if @packet.restore!
      ModerationLog.log_action(
        actor: current_hackr,
        action: "restore_packet",
        chat_message: @packet,
        target: @packet.grid_hackr
      )
      set_flash_success("Packet by @#{@packet.grid_hackr.hackr_alias} restored.")
    else
      set_flash_error("Failed to restore packet.")
    end

    redirect_back(fallback_location: packets_admin_uplink_index_path)
  end

  # GET /root/uplink/punishments
  def punishments
    @punishments = UserPunishment.includes(:grid_hackr, :issued_by).order(created_at: :desc)

    # Filter by type
    case params[:type]
    when "squelch"
      @punishments = @punishments.squelches
    when "blackout"
      @punishments = @punishments.blackouts
    end

    # Filter by status
    case params[:status]
    when "active"
      @punishments = @punishments.active
    when "expired"
      @punishments = @punishments.expired
    end
  end

  # POST /root/uplink/users/:id/squelch
  def squelch_user
    hackr = find_hackr_by_id_or_username
    return redirect_back(fallback_location: punishments_admin_uplink_index_path) unless hackr
    duration = params[:duration_minutes].presence&.to_i
    reason = params[:reason].presence

    if UserPunishment.squelched?(hackr)
      set_flash_error("#{hackr.hackr_alias} is already squelched.")
    else
      UserPunishment.squelch!(hackr, issued_by: current_hackr, duration_minutes: duration, reason: reason)
      set_flash_success("#{hackr.hackr_alias} has been squelched#{duration ? " for #{duration} minutes" : " permanently"}.")
    end

    redirect_back(fallback_location: punishments_admin_uplink_index_path)
  end

  # POST /root/uplink/users/:id/blackout
  def blackout_user
    hackr = find_hackr_by_id_or_username
    return redirect_back(fallback_location: punishments_admin_uplink_index_path) unless hackr
    duration = params[:duration_minutes].presence&.to_i
    reason = params[:reason].presence

    if UserPunishment.blackedout?(hackr)
      set_flash_error("#{hackr.hackr_alias} is already blackedout.")
    else
      UserPunishment.blackout!(hackr, issued_by: current_hackr, duration_minutes: duration, reason: reason)
      set_flash_success("#{hackr.hackr_alias} has been blackedout#{duration ? " for #{duration} minutes" : " permanently"}.")
    end

    redirect_back(fallback_location: punishments_admin_uplink_index_path)
  end

  # DELETE /root/uplink/punishments/:id
  def lift_punishment
    hackr_alias = @punishment.grid_hackr.hackr_alias
    @punishment.lift!(current_hackr)
    set_flash_success("Punishment lifted for @#{hackr_alias}.")
    redirect_back(fallback_location: punishments_admin_uplink_index_path)
  end

  # GET /root/uplink/moderation_log
  def moderation_log
    @logs = ModerationLog.includes(:actor, :target, :chat_message).recent

    # Filter by action
    @logs = @logs.by_action(params[:action_type]) if params[:action_type].present?

    # Filter by actor
    if params[:actor].present?
      actor = GridHackr.find_by(hackr_alias: params[:actor])
      @logs = actor ? @logs.by_actor(actor) : @logs.none
    end

    # Filter by target
    if params[:target].present?
      target = GridHackr.find_by(hackr_alias: params[:target])
      @logs = target ? @logs.by_target(target) : @logs.none
    end
  end

  private

  def set_channel
    @channel = ChatChannel.find_by!(slug: params[:slug])
  end

  def set_punishment
    @punishment = UserPunishment.find(params[:id])
  end

  def channel_params
    params.require(:chat_channel).permit(:name, :description, :is_active, :requires_livestream, :slow_mode_seconds, :minimum_role)
  end

  def find_hackr_by_id_or_username
    # Try to find by username first (from form)
    if params[:username].present?
      hackr = GridHackr.find_by("LOWER(hackr_alias) = ?", params[:username].downcase.delete("@"))
      unless hackr
        set_flash_error("User '#{params[:username]}' not found.")
        return nil
      end
      return hackr
    end

    # Fall back to finding by ID
    if params[:id].present? && params[:id] != "0"
      return GridHackr.find(params[:id])
    end

    set_flash_error("No user specified.")
    nil
  end
end
