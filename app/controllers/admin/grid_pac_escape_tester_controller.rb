# frozen_string_literal: true

class Admin::GridPacEscapeTesterController < Admin::ApplicationController
  before_action :require_dev_tools
  before_action :preselect_from_params, only: %i[new]
  before_action :load_session, only: %i[show command finish]

  # GET /root/grid_pac_escape_tester/new?hackr_id=N
  def new
    load_hackrs
  end

  # POST /root/grid_pac_escape_tester
  def create
    @hackr = GridHackr.find_by(id: params[:hackr_id])
    unless @hackr
      flash.now[:error] = "Hackr is required."
      load_hackrs
      return render :new, status: :unprocessable_entity
    end

    impound = params[:impound] == "1"
    service = Grid::PacEscapeTesterService.new(@hackr)
    service.start!(impound: impound)

    session[:pac_tester] = {"hackr_id" => @hackr.id}
    redirect_to admin_grid_pac_escape_tester_path
  rescue Grid::PacEscapeTesterService::AlreadyInBreach,
    Grid::PacEscapeTesterService::AlreadyCaptured,
    Grid::PacEscapeTesterService::NoContainmentRoom => e
    flash.now[:error] = e.message
    load_hackrs
    render :new, status: :unprocessable_entity
  end

  # GET /root/grid_pac_escape_tester
  def show
    result = Grid::CommandParser.new(@hackr, "look").execute
    @initial_output = result.is_a?(Hash) ? result[:output] : result
  end

  # POST /root/grid_pac_escape_tester/command
  def command
    input = params[:input].to_s.strip
    if input.empty?
      return render json: {output: "<span style='color: #fbbf24;'>Please enter a command.</span>", session_active: true}
    end

    result = Grid::CommandParser.new(@hackr, input).execute
    output = result.is_a?(Hash) ? result[:output] : result

    @hackr.reload
    escaped = !Grid::ContainmentService.captured?(@hackr)

    render json: {output: output, session_active: true, escaped: escaped}
  end

  # DELETE /root/grid_pac_escape_tester
  def finish
    Grid::PacEscapeTesterService.new(@hackr).restore!
    session.delete(:pac_tester)

    set_flash_success("PAC Escape Test ended. #{@hackr.hackr_alias} restored to original state.")
    redirect_to admin_grid_hackr_path(@hackr)
  end

  private

  def preselect_from_params
    @hackr = GridHackr.find_by(id: params[:hackr_id]) if params[:hackr_id].present?
  end

  def load_session
    tester = session[:pac_tester]
    unless tester
      set_flash_error("No active PAC Escape Tester session.")
      return redirect_to admin_grid_hackrs_path
    end

    @hackr = GridHackr.find_by(id: tester["hackr_id"])
    unless @hackr
      session.delete(:pac_tester)
      set_flash_error("Session hackr no longer exists.")
      redirect_to admin_grid_hackrs_path
    end
  end

  def load_hackrs
    @hackrs = GridHackr.order(:hackr_alias)
    @breach_hackr_ids = GridHackrBreach.where(state: "active").distinct.pluck(:grid_hackr_id).to_set
  end
end
