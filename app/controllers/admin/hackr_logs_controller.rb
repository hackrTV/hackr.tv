class Admin::HackrLogsController < Admin::ApplicationController
  before_action :set_hackr_log, only: [:edit, :update, :destroy]

  def index
    @hackr_logs = HackrLog.includes(:author).ordered
  end

  def new
    @hackr_log = HackrLog.new
  end

  def create
    @hackr_log = HackrLog.new(hackr_log_params)
    @hackr_log.author = current_hackr

    # Auto-set published_at if publishing
    if @hackr_log.published? && @hackr_log.published_at.nil?
      @hackr_log.published_at = Time.current
    end

    if @hackr_log.save
      set_flash_success("HackrLog '#{@hackr_log.title}' created successfully!")
      redirect_to admin_hackr_logs_path
    else
      flash.now[:error] = "Failed to create log: #{@hackr_log.errors.full_messages.join(", ")}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Auto-set published_at if publishing for first time
    if hackr_log_params[:published] == "1" && !@hackr_log.published? && @hackr_log.published_at.nil?
      @hackr_log.published_at = Time.current
    end

    if @hackr_log.update(hackr_log_params)
      set_flash_success("HackrLog '#{@hackr_log.title}' updated successfully!")
      redirect_to admin_hackr_logs_path
    else
      flash.now[:error] = "Failed to update log: #{@hackr_log.errors.full_messages.join(", ")}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    title = @hackr_log.title
    @hackr_log.destroy
    set_flash_success("HackrLog '#{title}' deleted successfully!")
    redirect_to admin_hackr_logs_path
  end

  private

  def set_hackr_log
    @hackr_log = HackrLog.find_by!(slug: params[:id])
  end

  def hackr_log_params
    params.require(:hackr_log).permit(:title, :slug, :body, :published)
  end
end
