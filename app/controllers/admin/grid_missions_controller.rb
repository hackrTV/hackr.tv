# /root/grid_missions — the missions ledger and the mission record
# (fields, the GIVER / ARC / PREREQ pickers, // OBJECTIVES // and
# // REWARDS // as row editors) as console screens (2026-11-01;
# root_console.css). The record screen is the edit screen: show
# redirects there, saves stay on it; edit and a rejected save add one
# blank objective and reward row (an objective with no type and no
# label, or a reward with no type, is dropped on save);
# ?grid_mission_arc_id= prefills a new mission (the arc record's [+] NEW
# MISSION); a DIALOGUE PATH that is not a JSON array is refused with a
# 422 instead of saving as no gate.
class Admin::GridMissionsController < Admin::ApplicationController
  include Admin::Versionable

  versionable GridMission, find_by: :slug, children: [:grid_mission_objectives, :grid_mission_rewards]

  before_action :set_mission, only: %i[show edit update destroy]

  def index
    @missions = GridMission.ordered
      .includes(:grid_mission_arc, :giver_mob, :prereq_mission, :grid_mission_objectives, :grid_mission_rewards)
      .to_a
    @active_counts = GridHackrMission.active.group(:grid_mission_id).count
    @completed_counts = GridHackrMission.completed.group(:grid_mission_id).sum(:turn_in_count)
  end

  def show
    redirect_to edit_admin_grid_mission_path(@mission)
  end

  def new
    @mission = GridMission.new(
      published: true,
      position: (GridMission.maximum(:position) || 0) + 1,
      grid_mission_arc_id: params[:grid_mission_arc_id]
    )
    @mission.grid_mission_objectives.build(position: 1)
    @mission.grid_mission_rewards.build(position: 1, reward_type: "xp")
    load_selects
  end

  def create
    @mission = GridMission.new(mission_params)
    if save_mission
      set_flash_success("Mission '#{@mission.name}' created.")
      redirect_to edit_admin_grid_mission_path(@mission)
    else
      flash.now[:error] = @mission.errors.full_messages.join(", ")
      build_blank_rows
      load_selects
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    build_blank_rows
    load_selects
  end

  def update
    @mission.assign_attributes(mission_params)
    if save_mission
      set_flash_success("Mission '#{@mission.name}' updated.")
      redirect_to edit_admin_grid_mission_path(@mission)
    else
      flash.now[:error] = @mission.errors.full_messages.join(", ")
      build_blank_rows
      load_selects
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @mission.name
    active_count = @mission.grid_hackr_missions.active.count

    if active_count > 0
      set_flash_error("Cannot delete '#{name}' — #{active_count} hackr(s) currently have this mission active. They must abandon it first.")
      redirect_to edit_admin_grid_mission_path(@mission)
      return
    end

    # Destroy hackr mission records first (cascades their objectives),
    # then the mission itself destroys its definition objectives/rewards.
    ActiveRecord::Base.transaction do
      @mission.grid_hackr_missions.destroy_all
      @mission.destroy!
    end
    set_flash_success("Mission '#{name}' deleted.")
    redirect_to admin_grid_missions_path
  end

  private

  def set_mission
    # GridMission overrides to_param to return slug, so URL helpers emit
    # slug-based paths — look up by slug to match.
    @mission = GridMission.find_by!(slug: params[:id])
  end

  # Saves unless the DIALOGUE PATH failed to parse (mission_params leaves
  # the stored value alone and notes why), then reports it with the
  # model's own errors.
  def save_mission
    return @mission.save unless @dialogue_path_error
    @mission.valid?
    @mission.errors.add(:dialogue_path, @dialogue_path_error)
    false
  end

  # The one blank objective and reward row the record screen always
  # offers, after the last position.
  def build_blank_rows
    @mission.grid_mission_objectives.build(position: (@mission.grid_mission_objectives.map(&:position).compact.max || 0) + 1)
    @mission.grid_mission_rewards.build(position: (@mission.grid_mission_rewards.map(&:position).compact.max || 0) + 1)
  end

  def load_selects
    @arcs = GridMissionArc.ordered
    @missions_for_prereq = GridMission.ordered.includes(:grid_mission_arc).where.not(id: @mission.id)
    # Restrict giver choices to mob types that plausibly hand out work:
    # quest_givers (obvious) and vendors (can offer repeatable
    # commerce-flavored missions like "spend N CRED at my shop").
    # `lore` and `special` mobs exist for flavor only and would be a
    # miscast as mission givers.
    @mobs = GridMob.where(mob_type: %w[quest_giver vendor])
      .order(:name).includes(:grid_room)
    @factions = GridFaction.order(:name)
  end

  def mission_params
    permitted = params.require(:grid_mission).permit(
      :slug, :name, :description, :giver_mob_id, :grid_mission_arc_id,
      :prereq_mission_id, :min_clearance, :min_rep_faction_id, :min_rep_value,
      :repeatable, :position, :published,
      grid_mission_objectives_attributes: %i[id position objective_type label target_slug target_count _destroy],
      grid_mission_rewards_attributes: %i[id position reward_type amount target_slug quantity _destroy]
    )
    # Parse dialogue_path JSON (array of topic keys, or blank for no gate)
    raw_dp = params[:grid_mission][:dialogue_path_json]
    parsed = raw_dp.present? ? JSON.parse(raw_dp) : nil
    if parsed.nil? || parsed.is_a?(Array)
      permitted[:dialogue_path] = parsed
    else
      @dialogue_path_error = "must be a JSON array of topic keys"
    end
    permitted
  rescue JSON::ParserError => e
    @dialogue_path_error = "is not valid JSON: #{e.message}"
    permitted
  end
end
