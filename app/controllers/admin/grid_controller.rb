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
