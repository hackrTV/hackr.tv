# frozen_string_literal: true

class Admin::GridNpcDialogueTesterController < Admin::ApplicationController
  before_action :require_dev_tools
  before_action :preselect_from_params, only: %i[new]
  before_action :load_session, only: %i[show command finish]

  # GET /root/grid_npc_dialogue_tester/new?hackr_id=N&mob_id=N
  def new
    load_combobox_data
  end

  # POST /root/grid_npc_dialogue_tester
  def create
    @hackr = GridHackr.find_by(id: params[:hackr_id])
    mob = GridMob.find_by(id: params[:mob_id])

    unless @hackr && mob
      flash.now[:error] = "Hackr and Mob are both required."
      load_combobox_data
      return render :new, status: :unprocessable_entity
    end

    service = Grid::NpcDialogueSessionService.new(@hackr)
    service.start!(mob: mob)

    session[:npc_tester] = {
      "hackr_id" => @hackr.id,
      "mob_id" => mob.id
    }

    redirect_to admin_grid_npc_dialogue_tester_path
  rescue Grid::NpcDialogueSessionService::AlreadyInBreach => e
    flash.now[:error] = e.message
    load_combobox_data
    render :new, status: :unprocessable_entity
  end

  # GET /root/grid_npc_dialogue_tester
  def show
    result = Grid::NpcDialogueCommandParser.new(@hackr, "look").execute
    @initial_output = result.is_a?(Hash) ? result[:output] : result
  end

  # POST /root/grid_npc_dialogue_tester/command
  def command
    input = params[:input].to_s.strip
    if input.empty?
      return render json: {output: "<span style='color: #fbbf24;'>Please enter a command.</span>", session_active: true}
    end

    result = Grid::NpcDialogueCommandParser.new(@hackr, input).execute
    output = result.is_a?(Hash) ? result[:output] : result
    event = result.is_a?(Hash) ? result[:event] : nil

    render json: {output: output, session_active: true, event: event}
  end

  # DELETE /root/grid_npc_dialogue_tester
  def finish
    Grid::NpcDialogueSessionService.new(@hackr).restore!
    session.delete(:npc_tester)

    set_flash_success("NPC Dialogue Test ended. #{@hackr.hackr_alias} returned to original room.")
    redirect_to admin_grid_hackr_path(@hackr)
  end

  private

  def preselect_from_params
    @hackr = GridHackr.find_by(id: params[:hackr_id]) if params[:hackr_id].present?
    @mob = GridMob.find_by(id: params[:mob_id]) if params[:mob_id].present?
  end

  def load_session
    tester = session[:npc_tester]
    unless tester
      set_flash_error("No active NPC Dialogue Tester session.")
      return redirect_to admin_grid_hackrs_path
    end

    @hackr = GridHackr.find_by(id: tester["hackr_id"])
    @mob = GridMob.find_by(id: tester["mob_id"])

    unless @hackr && @mob
      session.delete(:npc_tester)
      set_flash_error("Session hackr or mob no longer exists.")
      redirect_to admin_grid_hackrs_path
    end
  end

  def load_combobox_data
    @hackrs = GridHackr.order(:hackr_alias)
    @mobs = GridMob
      .joins(grid_room: {grid_zone: :grid_region})
      .includes(grid_room: {grid_zone: :grid_region})
      .order("grid_regions.name, grid_zones.name, grid_rooms.name, grid_mobs.name")
  end
end
