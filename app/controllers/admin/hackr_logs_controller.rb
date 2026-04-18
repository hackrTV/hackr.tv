class Admin::HackrLogsController < Admin::ApplicationController
  include Admin::Versionable

  versionable HackrLog, find_by: :slug

  before_action :set_log, only: %i[edit update destroy]

  def index
    @logs = HackrLog.includes(:grid_hackr).ordered
  end

  def new
    @log = HackrLog.new(published: false, timeline: "2120s")
    load_selects
  end

  def create
    @log = HackrLog.new(log_params)
    if @log.save
      set_flash_success("Hackr log '#{@log.title}' created.")
      redirect_to admin_hackr_logs_path
    else
      load_selects
      flash.now[:error] = @log.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_selects
  end

  def update
    if @log.update(log_params)
      set_flash_success("Hackr log '#{@log.title}' updated.")
      redirect_to admin_hackr_logs_path
    else
      load_selects
      flash.now[:error] = @log.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    title = @log.title
    @log.destroy!
    set_flash_success("Hackr log '#{title}' deleted.")
    redirect_to admin_hackr_logs_path
  end

  private

  def set_log
    @log = HackrLog.find_by!(slug: params[:id])
  end

  def load_selects
    @hackrs = GridHackr.order(:hackr_alias)
  end

  def log_params
    params.require(:hackr_log).permit(
      :title, :slug, :body, :timeline, :published, :published_at, :grid_hackr_id
    )
  end
end
