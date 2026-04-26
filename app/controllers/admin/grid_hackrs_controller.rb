# frozen_string_literal: true

class Admin::GridHackrsController < Admin::ApplicationController
  before_action :set_hackr, only: %i[show edit_stats update_stats warp perform_warp]
  before_action :require_dev_tools, only: %i[edit_stats update_stats warp perform_warp]

  # GET /root/grid_hackrs
  def index
    @hackrs = GridHackr.includes(:current_room).order(:hackr_alias)
    if params[:q].present?
      @hackrs = @hackrs.where("LOWER(hackr_alias) LIKE ?", "%#{params[:q].downcase}%")
    end
  end

  # GET /root/grid_hackrs/:id
  def show
    @stats = @hackr.current_stats
    @inventory = GridItem.in_inventory(@hackr).includes(:grid_item_definition).order(:name)
    @equipped = GridItem.equipped_by(@hackr).includes(:grid_item_definition)
    @loadout = @hackr.loadout_by_slot
    @cache = @hackr.default_cache
    @cred_balance = @cache&.balance || 0
    @active_breach = @hackr.active_breach
    @mining_rig = @hackr.grid_mining_rig
    @reputations = @hackr.grid_hackr_reputations
      .for_subject_type("GridFaction")
      .includes(:subject)
      .order(:subject_id)
    @active_missions = @hackr.grid_hackr_missions
      .where(status: "active")
      .includes(grid_mission: :grid_mission_arc)
      .order(:accepted_at)
    @feature_grants = @hackr.feature_grants.order(:feature)
  end

  # GET /root/grid_hackrs/:id/edit_stats
  def edit_stats
  end

  # PATCH /root/grid_hackrs/:id/update_stats
  def update_stats
    if params[:raw_json].present?
      begin
        parsed = JSON.parse(params[:raw_json])
        @hackr.update_column(:stats, parsed)
        @hackr.stats = parsed
        set_flash_success("Stats updated (raw JSON) for #{@hackr.hackr_alias}.")
        return redirect_to admin_grid_hackr_path(@hackr)
      rescue JSON::ParserError => e
        flash.now[:error] = "Invalid JSON: #{e.message}"
        return render :edit_stats, status: :unprocessable_entity
      end
    end

    sp = stat_params
    changes = {}

    # XP / clearance sync — XP takes priority when both change.
    xp_changed = sp[:xp].present? && sp[:xp].to_i != @hackr.stat("xp")
    cl_changed = sp[:clearance].present? && sp[:clearance].to_i != @hackr.stat("clearance")

    if xp_changed
      xp = sp[:xp].to_i.clamp(0, 999_999_999)
      changes["xp"] = xp
      changes["clearance"] = @hackr.clearance_for_xp(xp)
    elsif cl_changed
      cl = sp[:clearance].to_i.clamp(0, GridHackr::Stats::MAX_CLEARANCE)
      changes["clearance"] = cl
      changes["xp"] = GridHackr::Stats.xp_for_clearance(cl)
    end

    # Vitals
    %w[health energy psyche].each do |key|
      changes[key] = sp[key].to_i.clamp(0, 999) if sp[key].present?
    end

    # Other numeric stats
    %w[inspiration bonus_inventory_slots govcorp_debt facility_alert_level].each do |key|
      changes[key] = sp[key].to_i if sp[key].present?
    end

    # Boolean: captured
    if sp.key?(:captured)
      captured = sp[:captured] == "1"
      changes["captured"] = captured
      unless captured
        changes["captured_origin_room_id"] = nil
        changes["facility_alert_level"] = 0
      end
    end

    if changes.any?
      new_stats = (@hackr.stats || {}).merge(changes)
      @hackr.update_column(:stats, new_stats)
      @hackr.stats = new_stats
    end

    set_flash_success("Stats updated for #{@hackr.hackr_alias}.")
    redirect_to admin_grid_hackr_path(@hackr)
  end

  # GET /root/grid_hackrs/:id/warp
  def warp
    load_rooms
  end

  # POST /root/grid_hackrs/:id/perform_warp
  def perform_warp
    room = GridRoom.find_by(id: params[:room_id])
    unless room
      flash.now[:error] = "Room not found."
      load_rooms
      return render :warp, status: :unprocessable_entity
    end

    if @hackr.in_breach?
      flash.now[:error] = "Cannot warp #{@hackr.hackr_alias} — active BREACH in progress. Abort the breach first."
      load_rooms
      return render :warp, status: :unprocessable_entity
    end

    # Clear containment state if captured (batched write)
    if @hackr.stat("captured")
      new_stats = (@hackr.stats || {}).merge(
        "captured" => false,
        "captured_origin_room_id" => nil,
        "facility_alert_level" => 0
      )
      @hackr.update_column(:stats, new_stats)
      @hackr.stats = new_stats
    end

    @hackr.update!(current_room_id: room.id, zone_entry_room_id: room.id)

    zone_name = room.grid_zone&.name || "unknown zone"
    set_flash_success("#{@hackr.hackr_alias} warped to #{room.name} (#{zone_name}).")
    redirect_to admin_grid_hackr_path(@hackr)
  end

  private

  def set_hackr
    @hackr = GridHackr.find(params[:id])
  end

  def load_rooms
    @rooms = GridRoom.joins(grid_zone: :grid_region)
      .includes(grid_zone: :grid_region)
      .order("grid_regions.name, grid_zones.name, grid_rooms.name")
  end

  def stat_params
    params.require(:stats).permit(
      :health, :energy, :psyche, :inspiration,
      :xp, :clearance, :bonus_inventory_slots,
      :govcorp_debt, :facility_alert_level, :captured
    )
  end
end
