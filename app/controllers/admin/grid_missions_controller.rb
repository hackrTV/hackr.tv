class Admin::GridMissionsController < Admin::ApplicationController
  include Admin::Versionable
  versionable GridMission, find_by: :slug, children: [:grid_mission_objectives, :grid_mission_rewards]

  before_action :set_mission, only: %i[edit update destroy]

  def index
    @missions = GridMission.ordered
      .includes(:grid_mission_arc, :giver_mob, :grid_mission_objectives, :grid_mission_rewards)
      .to_a
    @active_counts = GridHackrMission.active.group(:grid_mission_id).count
    @completed_counts = GridHackrMission.completed.group(:grid_mission_id).sum(:turn_in_count)
  end

  def new
    @mission = GridMission.new(
      published: true,
      position: (GridMission.maximum(:position) || 0) + 1
    )
    @mission.grid_mission_objectives.build(position: 1)
    @mission.grid_mission_rewards.build(position: 1, reward_type: "xp")
    load_selects
  end

  def create
    @mission = GridMission.new(mission_params)
    if @mission.save
      set_flash_success("Mission '#{@mission.name}' created.")
      redirect_to admin_grid_missions_path
    else
      flash.now[:error] = @mission.errors.full_messages.join(", ")
      load_selects
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_selects
  end

  def update
    if @mission.update(mission_params)
      set_flash_success("Mission '#{@mission.name}' updated.")
      redirect_to admin_grid_missions_path
    else
      flash.now[:error] = @mission.errors.full_messages.join(", ")
      load_selects
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @mission.name
    @mission.destroy!
    set_flash_success("Mission '#{name}' deleted.")
    redirect_to admin_grid_missions_path
  end

  private

  def set_mission
    # GridMission overrides to_param to return slug, so URL helpers emit
    # slug-based paths — look up by slug to match.
    @mission = GridMission.find_by!(slug: params[:id])
  end

  def load_selects
    @arcs = GridMissionArc.ordered
    @missions_for_prereq = GridMission.ordered.where.not(id: @mission.id)
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
    params.require(:grid_mission).permit(
      :slug, :name, :description, :giver_mob_id, :grid_mission_arc_id,
      :prereq_mission_id, :min_clearance, :min_rep_faction_id, :min_rep_value,
      :repeatable, :position, :published,
      grid_mission_objectives_attributes: %i[id position objective_type label target_slug target_count _destroy],
      grid_mission_rewards_attributes: %i[id position reward_type amount target_slug quantity _destroy]
    )
  end
end
