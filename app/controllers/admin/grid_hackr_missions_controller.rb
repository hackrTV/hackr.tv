class Admin::GridHackrMissionsController < Admin::ApplicationController
  def index
    scope = GridHackrMission.includes(:grid_hackr, grid_mission: :giver_mob).order(accepted_at: :desc)
    scope = scope.where(status: params[:status]) if %w[active completed].include?(params[:status])

    if params[:hackr_alias].present?
      hackr = GridHackr.find_by("LOWER(hackr_alias) = ?", params[:hackr_alias].downcase)
      scope = hackr ? scope.where(grid_hackr_id: hackr.id) : GridHackrMission.none
    end

    @status_filter = params[:status]
    @hackr_alias_filter = params[:hackr_alias]
    @hackr_missions = scope.limit(200)
  end

  def show
    @hackr_mission = GridHackrMission.includes(
      grid_hackr_mission_objectives: :grid_mission_objective,
      grid_mission: :grid_mission_objectives
    ).find(params[:id])
  end
end
