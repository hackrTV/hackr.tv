class Admin::PulseWireController < Admin::ApplicationController
  before_action :set_pulse, only: [:signal_drop, :restore, :destroy]

  def index
    @pulses = Pulse.includes(:grid_hackr).timeline

    # Filter by status
    if params[:status] == "dropped"
      @pulses = @pulses.dropped
    elsif params[:status] == "active"
      @pulses = @pulses.active
    end

    # Filter by user
    if params[:username].present?
      hackr = GridHackr.find_by(hackr_alias: params[:username])
      @pulses = if hackr
        @pulses.where(grid_hackr_id: hackr.id)
      else
        @pulses.none
      end
    end

    # Search content
    if params[:search].present?
      @pulses = @pulses.where("content LIKE ?", "%#{params[:search]}%")
    end

    # Filter by date range
    if params[:start_date].present?
      @pulses = @pulses.where("pulsed_at >= ?", params[:start_date])
    end
    if params[:end_date].present?
      @pulses = @pulses.where("pulsed_at <= ?", params[:end_date])
    end
  end

  def signal_drops
    @pulses = Pulse.includes(:grid_hackr).dropped.timeline
  end

  def signal_drop
    if @pulse.signal_drop!
      set_flash_success("Pulse by @#{@pulse.grid_hackr.hackr_alias} has been signal-dropped.")
    else
      set_flash_error("Failed to signal-drop pulse.")
    end
    redirect_back(fallback_location: admin_pulse_wire_index_path)
  end

  def restore
    if @pulse.restore!
      set_flash_success("Pulse by @#{@pulse.grid_hackr.hackr_alias} has been restored.")
    else
      set_flash_error("Failed to restore pulse.")
    end
    redirect_back(fallback_location: signal_drops_admin_pulse_wire_index_path)
  end

  def destroy
    hackr_alias = @pulse.grid_hackr.hackr_alias
    if @pulse.destroy
      set_flash_success("Pulse by @#{hackr_alias} has been permanently deleted.")
    else
      set_flash_error("Failed to delete pulse.")
    end
    redirect_back(fallback_location: admin_pulse_wire_index_path)
  end

  def bulk_signal_drop
    pulse_ids = params[:pulse_ids] || []

    if pulse_ids.empty?
      set_flash_error("No pulses selected.")
      redirect_back(fallback_location: admin_pulse_wire_index_path)
      return
    end

    count = 0
    Pulse.where(id: pulse_ids).find_each do |pulse|
      count += 1 if pulse.signal_drop!
    end

    set_flash_success("Signal-dropped #{count} pulse#{"s" unless count == 1}.")
    redirect_back(fallback_location: admin_pulse_wire_index_path)
  end

  def bulk_destroy
    pulse_ids = params[:pulse_ids] || []

    if pulse_ids.empty?
      set_flash_error("No pulses selected.")
      redirect_back(fallback_location: admin_pulse_wire_index_path)
      return
    end

    count = Pulse.where(id: pulse_ids).destroy_all.count

    set_flash_success("Permanently deleted #{count} pulse#{"s" unless count == 1}.")
    redirect_back(fallback_location: admin_pulse_wire_index_path)
  end

  private

  def set_pulse
    @pulse = Pulse.find(params[:id])
  end
end
