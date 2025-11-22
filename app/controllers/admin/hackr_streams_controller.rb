class Admin::HackrStreamsController < Admin::ApplicationController
  before_action :set_stream, only: [:edit, :update, :destroy, :go_live, :end_stream]

  def index
    @hackr_streams = HackrStream.includes(:artist).recent
    @current_live = HackrStream.current_live
  end

  def new
    @hackr_stream = HackrStream.new
    @artists = Artist.order(:name)
  end

  def create
    @hackr_stream = HackrStream.new(hackr_stream_params)

    if @hackr_stream.save
      set_flash_success("Stream created successfully!")
      redirect_to admin_hackr_streams_path
    else
      @artists = Artist.order(:name)
      flash.now[:error] = "Failed to create stream: #{@hackr_stream.errors.full_messages.join(", ")}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @artists = Artist.order(:name)
  end

  def update
    if @hackr_stream.update(hackr_stream_params)
      set_flash_success("Stream updated successfully!")
      redirect_to admin_hackr_streams_path
    else
      @artists = Artist.order(:name)
      flash.now[:error] = "Failed to update stream: #{@hackr_stream.errors.full_messages.join(", ")}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @hackr_stream.destroy
    set_flash_success("Stream deleted successfully!")
    redirect_to admin_hackr_streams_path
  end

  def go_live
    # End any currently live streams first
    HackrStream.live.where.not(id: @hackr_stream.id).find_each(&:end_stream!)

    @hackr_stream.go_live!(@hackr_stream.url, @hackr_stream.title)
    set_flash_success("Stream is now LIVE!")
  rescue ActiveRecord::RecordInvalid => e
    set_flash_error("Failed to go live: #{e.record.errors.full_messages.join(", ")}")
  ensure
    redirect_to admin_hackr_streams_path
  end

  def end_stream
    @hackr_stream.end_stream!
    set_flash_success("Stream ended successfully!")
  rescue ActiveRecord::RecordInvalid => e
    set_flash_error("Failed to end stream: #{e.record.errors.full_messages.join(", ")}")
  ensure
    redirect_to admin_hackr_streams_path
  end

  private

  def set_stream
    @hackr_stream = HackrStream.find(params[:id])
  end

  def hackr_stream_params
    params.require(:hackr_stream).permit(:artist_id, :url, :title, :is_live)
  end
end
