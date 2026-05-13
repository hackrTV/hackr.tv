# frozen_string_literal: true

class Admin::GridTransitJourneysController < Admin::ApplicationController
  include Admin::DevToolsGate

  def index
    @journeys = GridTransitJourney.includes(:grid_hackr, :grid_transit_route, :grid_slipstream_route)
      .order(created_at: :desc)
      .limit(100)

    if params[:state].present?
      @journeys = @journeys.where(state: params[:state])
    end
    if params[:journey_type].present?
      @journeys = @journeys.where(journey_type: params[:journey_type])
    end
  end

  def show
    @journey = GridTransitJourney.includes(
      :grid_hackr, :grid_transit_route, :grid_slipstream_route,
      :current_stop, :current_leg, :origin_room, :destination_room
    ).find(params[:id])
  end

  def force_abandon
    require_dev_tools!
    journey = GridTransitJourney.find(params[:id])
    if journey.active?
      journey.update!(state: "abandoned", ended_at: Time.current)
      hackr = journey.grid_hackr
      hackr.update!(current_room: journey.origin_room) if journey.origin_room
      Grid::RoomVisitRecorder.record!(hackr: hackr, room: journey.origin_room) if journey.origin_room
      set_flash_success("Journey ##{journey.id} force-abandoned.")
    else
      flash[:error] = "Journey is not active (state: #{journey.state})."
    end
    redirect_to admin_grid_transit_journey_path(journey)
  end
end
