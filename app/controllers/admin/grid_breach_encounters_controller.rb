# frozen_string_literal: true

# /root/grid_breach_encounters — the encounters ledger and the encounter
# record as console screens (2026-11-01; root_console.css). Saves stay
# on the record (no show route); ?grid_breach_template_id= prefills a
# new encounter (the template record's [+] NEW ENCOUNTER).
class Admin::GridBreachEncountersController < Admin::ApplicationController
  include Admin::Versionable

  versionable GridBreachEncounter

  before_action :set_encounter, only: %i[edit update destroy make_available]

  def index
    @encounters = GridBreachEncounter
      .joins(:grid_breach_template, grid_room: :grid_zone)
      .includes(:grid_breach_template, grid_room: :grid_zone)
      .order("grid_rooms.name ASC, grid_breach_templates.position ASC")
    @active_counts = GridHackrBreach.where(state: "active")
      .group(:grid_breach_encounter_id).count
  end

  def new
    @encounter = GridBreachEncounter.new(state: "available", grid_breach_template_id: params[:grid_breach_template_id])
    load_selects
  end

  def create
    @encounter = GridBreachEncounter.new(encounter_params)

    if @encounter.save
      set_flash_success("Encounter placed in #{@encounter.grid_room&.name}.")
      redirect_to edit_admin_grid_breach_encounter_path(@encounter)
    else
      flash.now[:error] = @encounter.errors.full_messages.join(", ")
      load_selects
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_selects
  end

  def update
    if @encounter.update(encounter_params)
      set_flash_success("Encounter updated.")
      redirect_to edit_admin_grid_breach_encounter_path(@encounter)
    else
      flash.now[:error] = @encounter.errors.full_messages.join(", ")
      load_selects
      render :edit, status: :unprocessable_entity
    end
  end

  def make_available
    if @encounter.available?
      flash[:error] = "Encounter is already available."
    elsif @encounter.grid_hackr_breaches.where(state: "active").exists?
      flash[:error] = "Cannot reset — active breaches reference this encounter."
    elsif @encounter.update(state: "available", cooldown_until: nil)
      set_flash_success("Encounter '#{@encounter.name}' set to available.")
    else
      flash[:error] = @encounter.errors.full_messages.join(", ")
    end
    redirect_to admin_grid_breach_encounters_path
  end

  def destroy
    room_name = @encounter.grid_room&.name
    if @encounter.grid_hackr_breaches.where(state: "active").exists?
      flash[:error] = "Cannot delete — active breaches reference this encounter."
    else
      @encounter.destroy!
      set_flash_success("Encounter in '#{room_name}' deleted.")
    end
    redirect_to admin_grid_breach_encounters_path
  end

  private

  def set_encounter
    @encounter = GridBreachEncounter.find(params[:id])
  end

  def load_selects
    # Published templates, plus the one on record (an unpublished
    # template's encounter would otherwise lose it on save).
    @templates = GridBreachTemplate.published.or(GridBreachTemplate.where(id: @encounter.grid_breach_template_id)).ordered
    @rooms = GridRoom.includes(:grid_zone).joins(:grid_zone).order("grid_zones.name ASC, grid_rooms.name ASC")
  end

  def encounter_params
    params.require(:grid_breach_encounter).permit(
      :grid_breach_template_id, :grid_room_id, :state, :instance_seed
    )
  end
end
