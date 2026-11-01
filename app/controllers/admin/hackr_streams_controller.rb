# /root/hackr_streams — the streams ledger and the stream record as
# console screens (2026-10-31; root_console.css). The record screen is
# the edit screen (show redirects there); GO LIVE / END / CANCEL stay on
# the ledger's rows.
class Admin::HackrStreamsController < Admin::ApplicationController
  before_action :set_stream, only: [:show, :edit, :update, :destroy, :go_live, :end_stream, :cancel]

  def index
    @hackr_streams = HackrStream.includes(:artist).recent
    @current_live = HackrStream.current_live
  end

  def show
    redirect_to edit_admin_hackr_stream_path(@hackr_stream)
  end

  def new
    @hackr_stream = HackrStream.new
    @artists = Artist.order(:name)
  end

  def create
    @hackr_stream = HackrStream.new(hackr_stream_params)

    if @hackr_stream.save
      set_flash_success("Stream created successfully!")
      redirect_to edit_admin_hackr_stream_path(@hackr_stream)
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
    previous_schedule = @hackr_stream.scheduled_at
    @hackr_stream.assign_attributes(hackr_stream_params)
    # Auto-clear cancellation only when scheduled_at actually changes (the
    # datetime-local field resubmits the stored time on every save) —
    # compared as times to the second, never as strings.
    if @hackr_stream.cancelled_at.present? &&
        @hackr_stream.scheduled_at.present? &&
        @hackr_stream.scheduled_at.to_i != previous_schedule.to_i
      @hackr_stream.cancelled_at = nil
    end

    if @hackr_stream.save
      set_flash_success("Stream updated successfully!")
      redirect_to edit_admin_hackr_stream_path(@hackr_stream)
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

    @hackr_stream.go_live!(@hackr_stream.live_url, @hackr_stream.title)
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

  def cancel
    @hackr_stream.cancel!
    set_flash_success("Scheduled stream cancelled.")
  rescue ActiveRecord::RecordInvalid => e
    set_flash_error("Failed to cancel stream: #{e.record.errors.full_messages.join(", ")}")
  ensure
    redirect_to admin_hackr_streams_path
  end

  private

  def set_stream
    @hackr_stream = HackrStream.find(params[:id])
  end

  def hackr_stream_params
    params.require(:hackr_stream).permit(:artist_id, :live_url, :vod_url, :title, :is_live, :started_at, :ended_at, :scheduled_at, :cancelled_at)
  end
end
