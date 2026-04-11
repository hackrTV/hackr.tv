class Admin::GridShopListingsController < Admin::ApplicationController
  before_action :set_listing, only: [:edit, :update, :destroy, :restock]

  def index
    @listings = GridShopListing.includes(:grid_mob).order(:grid_mob_id, :name)
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
    @vendors = GridMob.where(mob_type: "vendor").includes(:grid_room).order(:name)
  end

  def create
    attrs, json_error = listing_params
    @listing = GridShopListing.new(attrs)

    if json_error.nil? && @listing.save
      set_flash_success("Listing '#{@listing.name}' created for #{@listing.grid_mob.name}.")
      redirect_to admin_grid_shop_listings_path(mob_id: @listing.grid_mob_id)
      return
    end

    if json_error
      @listing.valid? # populate other validation errors
      @listing.errors.add(:properties, json_error)
    end
    @vendors = GridMob.where(mob_type: "vendor").includes(:grid_room).order(:name)
    flash.now[:error] = @listing.errors.full_messages.join(", ")
    render :new, status: :unprocessable_entity
  end

  def edit
    @vendors = GridMob.where(mob_type: "vendor").includes(:grid_room).order(:name)
  end

  def update
    attrs, json_error = listing_params
    if json_error
      @listing.assign_attributes(attrs)
      @listing.errors.add(:properties, json_error)
      @vendors = GridMob.where(mob_type: "vendor").includes(:grid_room).order(:name)
      flash.now[:error] = @listing.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
      return
    end

    if @listing.update(attrs)
      set_flash_success("Listing '#{@listing.name}' updated.")
      redirect_to admin_grid_shop_listings_path(mob_id: @listing.grid_mob_id)
    else
      @vendors = GridMob.where(mob_type: "vendor").includes(:grid_room).order(:name)
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

  # Returns [permitted_attrs, json_error_message_or_nil].
  # On invalid JSON, :properties is omitted from attrs entirely (preserving
  # existing values on update) and a human-readable error is returned.
  def listing_params
    permitted = params.require(:grid_shop_listing).permit(
      :grid_mob_id, :name, :description, :item_type, :rarity,
      :base_price, :sell_price, :stock, :max_stock,
      :restock_amount, :restock_interval_hours,
      :active, :rotation_pool, :min_clearance
    )

    json_source = params[:grid_shop_listing][:properties_json]
    if json_source.blank?
      permitted[:properties] = {}
      return [permitted, nil]
    end

    parsed = JSON.parse(json_source)
    unless parsed.is_a?(Hash)
      return [permitted, "must be a JSON object (e.g. {\"slot\": \"gpu\"})"]
    end

    permitted[:properties] = parsed
    [permitted, nil]
  rescue JSON::ParserError => e
    [permitted, "is not valid JSON: #{e.message}"]
  end
end
