class Admin::GridFactionsController < Admin::ApplicationController
  include Admin::Versionable
  versionable GridFaction

  before_action :set_faction, only: [:edit, :update, :destroy]

  def index
    @factions = GridFaction.ordered.includes(:parent, :incoming_rep_links, :outgoing_rep_links).to_a
    @rep_links = GridFactionRepLink.includes(:source_faction, :target_faction).to_a
  end

  def new
    @faction = GridFaction.new(kind: "collective", position: 0)
  end

  def create
    @faction = GridFaction.new(faction_params)
    if @faction.save
      set_flash_success("Faction '#{@faction.name}' created.")
      redirect_to admin_grid_factions_path
    else
      flash.now[:error] = @faction.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @faction.update(faction_params)
      set_flash_success("Faction '#{@faction.name}' updated.")
      redirect_to admin_grid_factions_path
    else
      flash.now[:error] = @faction.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @faction.name
    if @faction.grid_zones.any? || @faction.grid_mobs.any?
      set_flash_error("Can't delete '#{name}' — zones or mobs still reference it.")
    else
      @faction.destroy!
      set_flash_success("Faction '#{name}' deleted.")
    end
    redirect_to admin_grid_factions_path
  end

  # Bulk-replace rep links from a single form submission. Simpler than
  # per-row REST for a small graph that's edited holistically.
  def update_rep_links
    raw = params[:rep_links] || []
    raw = raw.values if raw.is_a?(ActionController::Parameters)
    desired = []
    raw.each do |attrs|
      attrs = attrs.permit(:source_slug, :target_slug, :weight) if attrs.is_a?(ActionController::Parameters)
      next if attrs["source_slug"].blank? || attrs["target_slug"].blank?
      next if attrs["weight"].blank? || attrs["weight"].to_f.zero?

      source = GridFaction.find_by(slug: attrs["source_slug"])
      target = GridFaction.find_by(slug: attrs["target_slug"])
      next unless source && target
      next if source.id == target.id

      desired << {source: source, target: target, weight: attrs["weight"].to_f}
    end

    GridFactionRepLink.transaction do
      desired_keys = desired.map { |d| [d[:source].id, d[:target].id] }.to_set
      GridFactionRepLink.find_each do |link|
        link.destroy! unless desired_keys.include?([link.source_faction_id, link.target_faction_id])
      end
      desired.each do |d|
        link = GridFactionRepLink.find_or_initialize_by(source_faction_id: d[:source].id, target_faction_id: d[:target].id)
        link.weight = d[:weight]
        link.save! if link.changed? || link.new_record?
      end
    end

    set_flash_success("Rep-link graph updated (#{desired.size} link#{"s" unless desired.size == 1}).")
    redirect_to admin_grid_factions_path
  rescue ActiveRecord::RecordInvalid => e
    set_flash_error("Rep-link update rejected: #{e.record.errors.full_messages.join(", ")}")
    redirect_to admin_grid_factions_path
  end

  private

  def set_faction
    @faction = GridFaction.find(params[:id])
  end

  def faction_params
    params.require(:grid_faction).permit(
      :name, :slug, :description, :color_scheme, :kind, :position, :parent_id, :artist_id
    )
  end
end
