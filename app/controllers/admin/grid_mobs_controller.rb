class Admin::GridMobsController < Admin::ApplicationController
  include Admin::Versionable

  versionable GridMob

  before_action :set_mob, only: %i[edit update destroy]

  def index
    @mobs = GridMob.includes(:grid_room, :grid_faction).order(:name)
  end

  def new
    @mob = GridMob.new
    load_selects
  end

  def create
    @mob = GridMob.new(mob_params)
    if @mob.save
      set_flash_success("Mob '#{@mob.name}' created.")
      redirect_to admin_grid_mobs_path
    else
      load_selects
      flash.now[:error] = @mob.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_selects
  end

  def update
    if @mob.update(mob_params)
      set_flash_success("Mob '#{@mob.name}' updated.")
      redirect_to admin_grid_mobs_path
    else
      load_selects
      flash.now[:error] = @mob.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @mob.name
    if @mob.grid_shop_listings.any?
      set_flash_error("Can't delete '#{name}' — shop listings still reference it.")
    else
      @mob.destroy!
      set_flash_success("Mob '#{name}' deleted.")
    end
    redirect_to admin_grid_mobs_path
  end

  private

  def set_mob
    @mob = GridMob.find(params[:id])
  end

  def load_selects
    @rooms = GridRoom.includes(:grid_zone).joins(:grid_zone).order("grid_zones.name, grid_rooms.name")
    @factions = GridFaction.ordered
  end

  def mob_params
    permitted = params.require(:grid_mob).permit(
      :name, :description, :mob_type, :grid_room_id, :grid_faction_id
    )
    # Parse JSON fields
    %w[dialogue_tree vendor_config].each do |json_field|
      raw = params[:grid_mob][:"#{json_field}_json"]
      permitted[json_field] = if raw.blank?
        {}
      else
        JSON.parse(raw)
      end
    rescue JSON::ParserError
      permitted[json_field] = {}
    end
    permitted
  end
end
