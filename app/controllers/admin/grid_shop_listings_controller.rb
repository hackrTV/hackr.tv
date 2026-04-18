class Admin::GridShopListingsController < Admin::ApplicationController
  include Admin::Versionable

  versionable GridShopListing

  before_action :set_listing, only: [:edit, :update, :destroy, :restock]
  before_action :load_selects, only: [:new, :edit]

  def index
    @listings = GridShopListing.includes(:grid_mob, :grid_item_definition)
      .joins(:grid_item_definition)
      .order(:grid_mob_id, "grid_item_definitions.name")
    @listings = @listings.where(grid_mob_id: params[:mob_id]) if params[:mob_id].present?
    @vendors = GridMob.where(mob_type: "vendor").includes(:grid_room).order(:name)
  end

  def new
    @listing = GridShopListing.new(
      restock_amount: 1,
      restock_interval_hours: 24,
      min_clearance: 0,
      active: true,
      rotation_pool: false
    )
  end

  def create
    @listing = GridShopListing.new(listing_params)

    if @listing.save
      set_flash_success("Listing '#{@listing.name}' created for #{@listing.grid_mob.name}.")
      redirect_to admin_grid_shop_listings_path(mob_id: @listing.grid_mob_id)
    else
      load_selects
      flash.now[:error] = @listing.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @listing.update(listing_params)
      set_flash_success("Listing '#{@listing.name}' updated.")
      redirect_to admin_grid_shop_listings_path(mob_id: @listing.grid_mob_id)
    else
      load_selects
      flash.now[:error] = @listing.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @listing.name
    mob_id = @listing.grid_mob_id
    @listing.destroy!
    set_flash_success("Listing '#{name}' deleted.")
    redirect_to admin_grid_shop_listings_path(mob_id: mob_id)
  end

  def restock
    if @listing.max_stock.present?
      @listing.update!(stock: @listing.max_stock, next_restock_at: Time.current + @listing.restock_interval_hours.hours)
      set_flash_success("'#{@listing.name}' restocked to #{@listing.max_stock}.")
    else
      set_flash_error("'#{@listing.name}' has unlimited stock.")
    end
    redirect_to admin_grid_shop_listings_path(mob_id: @listing.grid_mob_id)
  end

  private

  def set_listing
    @listing = GridShopListing.find(params[:id])
  end

  def load_selects
    @vendors = GridMob.where(mob_type: "vendor").includes(:grid_room).order(:name)
    @definitions = GridItemDefinition.ordered
  end

  def listing_params
    params.require(:grid_shop_listing).permit(
      :grid_mob_id, :grid_item_definition_id,
      :base_price, :sell_price, :stock, :max_stock,
      :restock_amount, :restock_interval_hours,
      :active, :rotation_pool, :min_clearance
    )
  end
end
