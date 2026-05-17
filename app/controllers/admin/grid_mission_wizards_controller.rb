class Admin::GridMissionWizardsController < Admin::ApplicationController
  def new
    load_selects
  end

  def create
    result = {}

    ActiveRecord::Base.transaction do
      # Step 1: Arc (optional)
      if params[:arc_mode] == "create"
        arc = GridMissionArc.create!(arc_params)
        result[:arc] = arc
      elsif params[:arc_mode] == "select" && params[:arc_id].present?
        result[:arc] = GridMissionArc.find(params[:arc_id])
      end

      # Step 2/3: Room (only if creating new mob AND creating new room)
      if params[:mob_mode] == "create" && params[:room_mode] == "create"
        room = GridRoom.create!(room_params)
        result[:room] = room
      end

      # Step 2: Giver Mob
      if params[:mob_mode] == "create"
        room_id = result[:room]&.id || params[:mob_room_id].presence
        mob = GridMob.create!(mob_create_params.merge(
          grid_room_id: room_id,
          mob_type: "quest_giver"
        ))
        result[:mob] = mob
      elsif params[:mob_mode] == "select" && params[:mob_id].present?
        result[:mob] = GridMob.find(params[:mob_id])
      end

      # Step 4-6: Mission with objectives and rewards
      mission = GridMission.new(mission_params)
      mission.giver_mob_id = result[:mob]&.id
      mission.grid_mission_arc_id = result[:arc]&.id
      mission.save!
      result[:mission] = mission
    end

    set_flash_success("Mission '#{result[:mission].name}' created via wizard.")
    redirect_to admin_grid_missions_path
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:error] = e.record.errors.full_messages.join(", ")
    load_selects
    render :new, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound => e
    flash.now[:error] = "Referenced record not found: #{e.message}"
    load_selects
    render :new, status: :unprocessable_entity
  rescue ActionController::ParameterMissing => e
    flash.now[:error] = "Missing required fields: #{e.message}"
    load_selects
    render :new, status: :unprocessable_entity
  end

  private

  def load_selects
    @arcs = GridMissionArc.ordered
    @mobs = GridMob.where(mob_type: %w[quest_giver vendor])
      .order(:name).includes(:grid_room)
    @rooms = GridRoom.includes(grid_zone: :grid_region)
      .joins(:grid_zone).order("grid_zones.name, grid_rooms.name")
    @zones = GridZone.includes(:grid_region).order(:name)
    @factions = GridFaction.order(:name)
    @missions_for_prereq = GridMission.ordered.includes(:grid_mission_arc)
  end

  def arc_params
    params.require(:new_arc).permit(:slug, :name, :description, :position, :published)
  end

  def room_params
    params.require(:new_room).permit(:name, :slug, :grid_zone_id, :room_type, :min_clearance)
  end

  def mob_create_params
    params.require(:new_mob).permit(:name, :description)
  end

  def mission_params
    permitted = params.require(:mission).permit(
      :slug, :name, :description, :min_clearance,
      :prereq_mission_id, :min_rep_faction_id, :min_rep_value,
      :repeatable, :position, :published,
      grid_mission_objectives_attributes: %i[position objective_type label target_slug target_count],
      grid_mission_rewards_attributes: %i[position reward_type amount target_slug quantity]
    )
    # Parse dialogue_path JSON
    raw_dp = params[:mission][:dialogue_path_json]
    permitted[:dialogue_path] = if raw_dp.blank?
      nil
    else
      parsed = JSON.parse(raw_dp)
      parsed.is_a?(Array) ? parsed : nil
    end
    permitted
  rescue JSON::ParserError
    permitted[:dialogue_path] = nil
    permitted
  end
end
