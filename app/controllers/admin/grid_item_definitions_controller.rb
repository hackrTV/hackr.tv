class Admin::GridItemDefinitionsController < Admin::ApplicationController
  include Admin::Versionable

  versionable GridItemDefinition, find_by: :slug, children: [:salvage_yields]

  before_action :set_definition, only: %i[edit update destroy]

  def index
    scope = GridItemDefinition.all
    scope = scope.by_item_type(params[:item_type]) if params[:item_type].present? && GridItem::ITEM_TYPES.include?(params[:item_type])
    @type_filter = params[:item_type]
    @definitions = scope.ordered
  end

  def new
    @definition = GridItemDefinition.new(value: 0, properties: {})
    @definition.salvage_yields.build
    load_yield_selects
  end

  def create
    attrs, json_error = definition_params
    @definition = GridItemDefinition.new(attrs)

    if json_error
      @definition.valid?
      @definition.errors.add(:properties, json_error)
      flash.now[:error] = @definition.errors.full_messages.join(", ")
      load_yield_selects
      render :new, status: :unprocessable_entity
      return
    end

    if @definition.save
      set_flash_success("Definition '#{@definition.name}' created.")
      redirect_to edit_admin_grid_item_definition_path(@definition)
    else
      flash.now[:error] = @definition.errors.full_messages.join(", ")
      load_yield_selects
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @sorted_yields = @definition.salvage_yields.ordered.to_a
    @sorted_yields << @definition.salvage_yields.build
    load_yield_selects
  end

  def update
    attrs, json_error = definition_params

    if json_error
      @definition.assign_attributes(attrs)
      @definition.errors.add(:properties, json_error)
      flash.now[:error] = @definition.errors.full_messages.join(", ")
      load_yield_selects
      render :edit, status: :unprocessable_entity
      return
    end

    if @definition.update(attrs)
      set_flash_success("Definition '#{@definition.name}' updated.")
      redirect_to edit_admin_grid_item_definition_path(@definition)
    else
      flash.now[:error] = @definition.errors.full_messages.join(", ")
      load_yield_selects
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @definition.grid_items.exists? || @definition.grid_shop_listings.exists?
      set_flash_error("Cannot delete '#{@definition.name}' — it has live items or shop listings.")
      redirect_to admin_grid_item_definitions_path
      return
    end

    if GridSalvageYield.where(output_definition_id: @definition.id).exists?
      set_flash_error("Cannot delete '#{@definition.name}' — it is referenced as a salvage yield output.")
      redirect_to admin_grid_item_definitions_path
      return
    end

    name = @definition.name
    if @definition.destroy
      set_flash_success("Definition '#{name}' deleted.")
    else
      set_flash_error("Failed to delete '#{name}': #{@definition.errors.full_messages.join(", ")}")
    end
    redirect_to admin_grid_item_definitions_path
  end

  private

  def set_definition
    @definition = GridItemDefinition.find_by!(slug: params[:id])
  end

  def load_yield_selects
    @all_definitions = GridItemDefinition.ordered
  end

  def definition_params
    permitted = params.require(:grid_item_definition).permit(
      :slug, :name, :description, :item_type, :rarity, :value,
      salvage_yields_attributes: %i[id output_definition_id quantity position _destroy]
    )

    json_source = params[:grid_item_definition][:properties_json]
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
