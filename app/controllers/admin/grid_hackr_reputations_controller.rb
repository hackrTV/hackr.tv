class Admin::GridHackrReputationsController < Admin::ApplicationController
  def index
    @hackrs = GridHackr.order(:hackr_alias)
    @factions = GridFaction.ordered.includes(:incoming_rep_links).to_a
    # Only leaf factions accept direct rep writes; aggregates are derived on
    # read from their incoming rep-links, so adjusting them silently no-ops.
    @adjustable_factions = @factions.reject(&:aggregate?)

    scope = GridHackrReputation.includes(:grid_hackr).where(subject_type: "GridFaction")

    if params[:hackr_alias].present?
      hackr = GridHackr.find_by("LOWER(hackr_alias) = ?", params[:hackr_alias].downcase)
      scope = hackr ? scope.where(grid_hackr: hackr) : scope.none
      @hackr_filter_missing = hackr.nil?
    end

    if params[:faction_slug].present?
      faction = GridFaction.find_by(slug: params[:faction_slug])
      scope = faction ? scope.where(subject_id: faction.id) : scope.none
    end

    @reputations = scope.order("grid_hackrs.hackr_alias, subject_id").to_a

    # Preload factions once to avoid N+1 on .subject lookup.
    faction_ids = @reputations.map(&:subject_id).uniq
    @faction_map = GridFaction.where(id: faction_ids).index_by(&:id)
  end

  def adjust
    hackr = GridHackr.find(params[:grid_hackr_id])
    faction = GridFaction.find(params[:grid_faction_id])
    delta = params[:delta].to_i
    reason = params[:reason].presence || "admin:manual"
    note = params[:note].presence

    if delta.zero?
      set_flash_error("Delta must be non-zero.")
      redirect_to admin_grid_hackr_reputations_path and return
    end

    service = Grid::ReputationService.new(hackr)
    result = service.adjust!(faction, delta, reason: reason, source: current_hackr, note: note)

    set_flash_success("#{hackr.hackr_alias} :: #{faction.display_name} #{"+" if result[:applied_delta].positive?}#{result[:applied_delta]} → #{result[:new_value]} (#{result[:tier_after][:label]}).")
    redirect_to admin_grid_hackr_reputations_path
  rescue Grid::ReputationService::SubjectMissing
    set_flash_error("Faction not found.")
    redirect_to admin_grid_hackr_reputations_path
  rescue Grid::ReputationService::AggregateSubjectNotAdjustable => e
    set_flash_error(e.message)
    redirect_to admin_grid_hackr_reputations_path
  end
end
