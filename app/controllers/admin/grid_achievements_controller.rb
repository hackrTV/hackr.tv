class Admin::GridAchievementsController < Admin::ApplicationController
  include Admin::Versionable
  versionable GridAchievement

  before_action :set_achievement, only: [:edit, :update, :destroy, :award]

  def index
    scope = GridAchievement.includes(:grid_hackr_achievements)
    scope = scope.by_category(params[:category]) if params[:category].present? && GridAchievement::CATEGORIES.include?(params[:category])
    @category_filter = params[:category]
    @achievements = scope.order(:category, :trigger_type, :name)
    @hackrs = GridHackr.order(:hackr_alias)
  end

  def new
    @achievement = GridAchievement.new(trigger_data: {}, xp_reward: 0, cred_reward: 0, category: "grid")
  end

  def create
    @achievement = GridAchievement.new(achievement_params)
    if @achievement.save
      set_flash_success("Achievement '#{@achievement.name}' created.")
      redirect_to admin_grid_achievements_path
    else
      flash.now[:error] = @achievement.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @achievement.update(achievement_params)
      set_flash_success("Achievement '#{@achievement.name}' updated.")
      redirect_to admin_grid_achievements_path
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

  def achievement_params
    permitted = params.require(:grid_achievement).permit(
      :slug, :name, :description, :badge_icon,
      :trigger_type, :xp_reward, :cred_reward, :category, :hidden
    )
    # Parse trigger_data from JSON string
    permitted[:trigger_data] = if params[:grid_achievement][:trigger_data_json].present?
      JSON.parse(params[:grid_achievement][:trigger_data_json])
    else
      {}
    end
    permitted
  rescue JSON::ParserError
    permitted[:trigger_data] = {}
    permitted
  end
end
