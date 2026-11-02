# /root/grid_achievements — the achievements ledger (CATEGORY row, FILTER,
# MANUAL AWARD) and the achievement record as console screens
# (2026-11-01; root_console.css). The record screen is the edit screen:
# show redirects there, saves stay on it; TRIGGER DATA that is not a
# JSON object is refused with a 422 instead of saving as {}.
class Admin::GridAchievementsController < Admin::ApplicationController
  include Admin::Versionable

  versionable GridAchievement

  before_action :set_achievement, only: [:show, :edit, :update, :destroy, :award]

  def index
    @category_filter = params[:category].presence_in(GridAchievement::CATEGORIES)
    scope = GridAchievement.includes(:grid_hackr_achievements)
    scope = scope.by_category(@category_filter) if @category_filter
    @achievements = scope.order(:category, :trigger_type, :name)
    @hackrs = GridHackr.order(:hackr_alias)
  end

  def show
    redirect_to edit_admin_grid_achievement_path(@achievement)
  end

  def new
    @achievement = GridAchievement.new(trigger_data: {}, xp_reward: 0, cred_reward: 0, category: "grid")
  end

  def create
    @achievement = GridAchievement.new(achievement_params)
    if save_achievement
      set_flash_success("Achievement '#{@achievement.name}' created.")
      redirect_to edit_admin_grid_achievement_path(@achievement)
    else
      flash.now[:error] = @achievement.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @achievement.assign_attributes(achievement_params)
    if save_achievement
      set_flash_success("Achievement '#{@achievement.name}' updated.")
      redirect_to edit_admin_grid_achievement_path(@achievement)
    else
      flash.now[:error] = @achievement.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @achievement.name
    @achievement.destroy!
    set_flash_success("Achievement '#{name}' deleted.")
    redirect_to admin_grid_achievements_path
  end

  def award
    hackr = GridHackr.find(params[:hackr_id])
    notification = Grid::AchievementAwarder.new(hackr, @achievement).award!

    if notification
      set_flash_success("Awarded '#{@achievement.name}' to #{hackr.hackr_alias}.")
    else
      set_flash_error("#{hackr.hackr_alias} already has '#{@achievement.name}'.")
    end
    redirect_to admin_grid_achievements_path
  end

  private

  def set_achievement
    @achievement = GridAchievement.find(params[:id])
  end

  # Saves unless the TRIGGER DATA failed to parse (achievement_params
  # leaves the stored value alone and notes why), then reports it with
  # the model's own errors.
  def save_achievement
    return @achievement.save unless @trigger_data_error
    @achievement.valid?
    @achievement.errors.add(:trigger_data, @trigger_data_error)
    false
  end

  def achievement_params
    permitted = params.require(:grid_achievement).permit(
      :slug, :name, :description, :badge_icon,
      :trigger_type, :xp_reward, :cred_reward, :category, :hidden
    )
    # Parse trigger_data from JSON string
    json_source = params[:grid_achievement][:trigger_data_json]
    parsed = json_source.present? ? JSON.parse(json_source) : {}
    if parsed.is_a?(Hash)
      permitted[:trigger_data] = parsed
    else
      @trigger_data_error = "must be a JSON object"
    end
    permitted
  rescue JSON::ParserError => e
    @trigger_data_error = "is not valid JSON: #{e.message}"
    permitted
  end
end
