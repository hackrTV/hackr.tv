# frozen_string_literal: true

class Admin::GridBreachTemplatesController < Admin::ApplicationController
  include Admin::Versionable

  versionable GridBreachTemplate, find_by: :slug

  before_action :set_template, only: %i[edit update destroy]

  def index
    @templates = GridBreachTemplate.ordered
    @active_counts = GridHackrBreach.where(state: "active")
      .group(:grid_breach_template_id).count
  end

  def new
    @template = GridBreachTemplate.new(
      published: false,
      tier: "standard",
      min_clearance: 0,
      pnr_threshold: 75,
      base_detection_rate: 5,
      cooldown_min: 300,
      cooldown_max: 600,
      xp_reward: 0,
      cred_reward: 0,
      position: (GridBreachTemplate.maximum(:position) || 0) + 1
    )
    load_selects
  end

  def create
    @template = GridBreachTemplate.new(template_params)
    unless parse_json_fields!
      flash.now[:error] = @template.errors.full_messages.join(", ")
      load_selects
      return render :new, status: :unprocessable_entity
    end

    if @template.save
      set_flash_success("Breach template '#{@template.name}' created.")
      redirect_to edit_admin_grid_breach_template_path(@template)
    else
      flash.now[:error] = @template.errors.full_messages.join(", ")
      load_selects
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_selects
  end

  def update
    @template.assign_attributes(template_params)
    unless parse_json_fields!
      flash.now[:error] = @template.errors.full_messages.join(", ")
      load_selects
      return render :edit, status: :unprocessable_entity
    end

    if @template.save
      set_flash_success("Breach template '#{@template.name}' updated.")
      redirect_to edit_admin_grid_breach_template_path(@template)
    else
      flash.now[:error] = @template.errors.full_messages.join(", ")
      load_selects
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @template.name
    if @template.grid_hackr_breaches.exists?
      flash[:error] = "Cannot delete '#{name}' — active or historical breaches reference this template."
    else
      @template.destroy!
      set_flash_success("Breach template '#{name}' deleted.")
    end
    redirect_to admin_grid_breach_templates_path
  end

  private

  def set_template
    @template = GridBreachTemplate.find_by!(slug: params[:id])
  end

  def load_selects
    @tiers = GridBreachTemplate::TIERS
  end

  def template_params
    params.require(:grid_breach_template).permit(
      :slug, :name, :description, :tier, :min_clearance,
      :pnr_threshold, :base_detection_rate,
      :cooldown_min, :cooldown_max, :xp_reward, :cred_reward,
      :requires_mission_slug, :requires_item_slug,
      :danger_level_min,
      :published, :position,
      :protocol_composition_json, :reward_table_json
    )
  end

  # Returns true on success, false on parse error (with error added to @template)
  def parse_json_fields!
    # Parse zone_slugs from CSV text field (splitting "" yields [])
    csv = params[:grid_breach_template].delete(:zone_slugs_csv)
    @template.zone_slugs = csv.split(",").map(&:strip).reject(&:blank?) unless csv.nil?

    if params[:grid_breach_template][:protocol_composition_json].present?
      parsed = JSON.parse(params[:grid_breach_template][:protocol_composition_json])
      unless parsed.is_a?(Array)
        @template.errors.add(:base, "Protocol composition must be a JSON array")
        return false
      end
      @template.protocol_composition = parsed
    end
    if params[:grid_breach_template][:reward_table_json].present?
      parsed = JSON.parse(params[:grid_breach_template][:reward_table_json])
      unless parsed.is_a?(Hash)
        @template.errors.add(:base, "Reward table must be a JSON object")
        return false
      end
      @template.reward_table = parsed
    end
    true
  rescue JSON::ParserError => e
    @template.errors.add(:base, "Invalid JSON: #{e.message}")
    false
  end
end
