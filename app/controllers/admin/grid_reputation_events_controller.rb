class Admin::GridReputationEventsController < Admin::ApplicationController
  PAGE_SIZE = 100

  def index
    @hackrs = GridHackr.order(:hackr_alias)
    @factions = GridFaction.ordered.to_a

    scope = GridReputationEvent.includes(:grid_hackr)

    if params[:hackr_alias].present?
      hackr = GridHackr.find_by("LOWER(hackr_alias) = ?", params[:hackr_alias].downcase)
      scope = hackr ? scope.where(grid_hackr: hackr) : scope.none
      @hackr_filter_missing = hackr.nil?
    end

    if params[:faction_slug].present?
      faction = GridFaction.find_by(slug: params[:faction_slug])
      scope = faction ? scope.where(subject_type: "GridFaction", subject_id: faction.id) : scope.none
    end

    if params[:reason].present?
      scope = scope.where("reason LIKE ?", "#{params[:reason]}%")
    end

    @events = scope.recent.limit(PAGE_SIZE).to_a

    subject_ids = @events.select { |e| e.subject_type == "GridFaction" }.map(&:subject_id).uniq
    @faction_map = GridFaction.where(id: subject_ids).index_by(&:id)
  end
end
