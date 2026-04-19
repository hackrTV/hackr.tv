class Admin::GridController < Admin::ApplicationController
  def index
    @online_hackrs = GridHackr.online.includes(:current_room).order(:hackr_alias)
    @recent_messages = GridMessage.order(created_at: :desc).includes(:grid_hackr, :room).limit(50)
    @all_hackrs = GridHackr.includes(:feature_grants).order(:hackr_alias)
  end

  def grant_feature
    hackr = GridHackr.find(params[:hackr_id])
    FeatureGrant.find_or_create_by!(grid_hackr: hackr, feature: params[:feature])
    set_flash_success("Granted '#{params[:feature]}' access to #{hackr.hackr_alias}.")
    redirect_to admin_grid_path
  end

  def revoke_feature
    hackr = GridHackr.find(params[:hackr_id])
    hackr.feature_grants.where(feature: params[:feature]).destroy_all
    set_flash_success("Revoked '#{params[:feature]}' access from #{hackr.hackr_alias}.")
    redirect_to admin_grid_path
  end

  def disable_login
    hackr = GridHackr.find(params[:hackr_id])
    if hackr.id == current_hackr.id
      set_flash_error("Cannot disable your own login.")
      return redirect_to admin_grid_path
    end
    hackr.update!(login_disabled: true)
    set_flash_success("Login disabled for #{hackr.hackr_alias}.")
    redirect_to admin_grid_path
  end

  def enable_login
    hackr = GridHackr.find(params[:hackr_id])
    hackr.update!(login_disabled: false)
    set_flash_success("Login re-enabled for #{hackr.hackr_alias}.")
    redirect_to admin_grid_path
  end

  def toggle_service_account
    hackr = GridHackr.find(params[:hackr_id])
    hackr.update!(service_account: !hackr.service_account?)
    status = hackr.service_account? ? "enabled" : "disabled"
    set_flash_success("Service account #{status} for #{hackr.hackr_alias}.")
    redirect_to admin_grid_path
  end

  def reset_totp
    hackr = GridHackr.find(params[:hackr_id])
    Grid::TotpService.new(hackr).disable_admin!(acting_admin: current_hackr)
    set_flash_success("2FA disabled for #{hackr.hackr_alias}.")
    redirect_to admin_grid_path
  rescue Grid::TotpService::NotEnabled
    set_flash_error("#{hackr.hackr_alias} does not have 2FA enabled.")
    redirect_to admin_grid_path
  end

  def broadcast
    message = params[:message].to_s.strip

    if message.blank?
      set_flash_error("Broadcast message cannot be empty!")
      redirect_to admin_grid_path
      return
    end

    # Create system message visible to all rooms
    GridRoom.find_each do |room|
      GridMessage.create!(
        room: room,
        grid_hackr: current_hackr,
        message_type: "system",
        content: "[SYSTEM BROADCAST] #{message}"
      )
    end

    # Broadcast via ActionCable to all rooms
    GridRoom.find_each do |room|
      GridChannel.broadcast_to(
        room,
        {
          type: "system_broadcast",
          message: "[SYSTEM BROADCAST] #{message}",
          sender: current_hackr.hackr_alias
        }
      )
    end

    set_flash_success("Broadcast sent to all rooms!")
    redirect_to admin_grid_path
  end
end
