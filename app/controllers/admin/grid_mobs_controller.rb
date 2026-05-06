class Admin::GridMobsController < Admin::ApplicationController
  include Admin::Versionable

  versionable GridMob

  before_action :set_mob, only: %i[edit update destroy add_listing remove_listing]

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
    load_listings if @mob.vendor?
  end

  def update
    if @mob.update(mob_params)
      set_flash_success("Mob '#{@mob.name}' updated.")
      redirect_to edit_admin_grid_mob_path(@mob)
    else
      load_selects
      load_listings if @mob.vendor?
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

  def add_listing
    listing = @mob.grid_shop_listings.build(listing_params)
    if listing.save
      set_flash_success("Listing '#{listing.name}' added.")
    else
      set_flash_error(listing.errors.full_messages.join(", "))
    end
    redirect_to edit_admin_grid_mob_path(@mob)
  end

  def remove_listing
    listing = @mob.grid_shop_listings.find(params[:listing_id])
    name = listing.name
    listing.destroy!
    set_flash_success("Listing '#{name}' removed.")
    redirect_to edit_admin_grid_mob_path(@mob)
  end

  private

  def set_mob
    @mob = GridMob.find(params[:id])
  end

  def load_selects
    @rooms = GridRoom.includes(grid_zone: :grid_region).joins(:grid_zone).order("grid_zones.name, grid_rooms.name")
    @factions = GridFaction.ordered
  end

  def load_listings
    @listings = @mob.grid_shop_listings.includes(:grid_item_definition).order("grid_item_definitions.name")
    @item_definitions = GridItemDefinition.ordered
  end

  def listing_params
    params.require(:grid_shop_listing).permit(
      :grid_item_definition_id, :base_price, :stock, :active,
      :min_clearance, :rotation_pool
    )
  end

  def mob_params
    permitted = params.require(:grid_mob).permit(
      :name, :description, :mob_type, :grid_room_id, :grid_faction_id
    )
    # Parse JSON fields
    %w[dialogue_tree vendor_config].each do |json_field|
      raw = params[:grid_mob][:"#{json_field}_json"]
      permitted[json_field] = begin
        raw.blank? ? {} : JSON.parse(raw)
      rescue JSON::ParserError
        {}
      end
    end
    permitted
  end
end
