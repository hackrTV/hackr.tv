# frozen_string_literal: true

class Admin::GridBreachSandboxController < Admin::ApplicationController
  before_action :require_dev_tools
  before_action :set_hackr, only: %i[new create]
  before_action :set_breach, only: %i[show command abort]

  # GET /root/grid_breach_sandbox/new?hackr_id=N
  def new
    load_templates
  end

  # POST /root/grid_breach_sandbox
  def create
    template = GridBreachTemplate.find_by(id: params[:template_id])
    unless template
      flash.now[:error] = "Template not found."
      load_templates
      return render :new, status: :unprocessable_entity
    end

    result = Grid::BreachService.start_sandbox!(hackr: @hackr, template: template)
    redirect_to admin_grid_breach_sandbox_path(result.hackr_breach)
  rescue Grid::BreachService::AlreadyInBreach => e
    flash.now[:error] = e.message
    load_templates
    render :new, status: :unprocessable_entity
  rescue Grid::BreachService::NoDeckEquipped, Grid::BreachService::DeckFried => e
    flash.now[:error] = "#{@hackr.hackr_alias}: #{e.message}"
    load_templates
    render :new, status: :unprocessable_entity
  end

  # GET /root/grid_breach_sandbox/:id
  def show
    @hackr = @breach.grid_hackr
    @initial_display = Grid::BreachRenderer.new(@breach).render_full
  end

  # POST /root/grid_breach_sandbox/:id/command
  def command
    @hackr = @breach.grid_hackr

    unless @breach.active?
      return render json: {output: sandbox_ended_message, breach_active: false}
    end

    input = params[:input].to_s.strip
    if input.empty?
      return render json: {output: "<span style='color: #fbbf24;'>Please enter a command.</span>", breach_active: true}
    end

    result = Grid::BreachCommandParser.new(@hackr, input, @breach).execute
    output = result.is_a?(Hash) ? result[:output] : result

    @breach.reload
    render json: {output: output, breach_active: @breach.active?}
  end

  # DELETE /root/grid_breach_sandbox/:id
  def abort
    @hackr = @breach.grid_hackr

    if @breach.active?
      Grid::BreachService.jackout!(hackr: @hackr)
    end

    set_flash_success("Sandbox breach aborted for #{@hackr.hackr_alias}.")
    redirect_to admin_grid_hackr_path(@hackr)
  end

  private

  def set_hackr
    @hackr = GridHackr.find(params[:hackr_id])
  end

  def set_breach
    @breach = GridHackrBreach.find(params[:id])
    unless @breach.sandbox?
      set_flash_error("Not a sandbox breach.")
      redirect_to admin_grid_hackrs_path
    end
  end

  def load_templates
    @templates = GridBreachTemplate.order(:tier, :min_clearance, :name)
  end

  def sandbox_ended_message
    "<span style='color: #9ca3af;'>Sandbox breach has ended. Return to the hackr inspector.</span>"
  end
end
