# frozen_string_literal: true

# /root/grid_transit_journeys — the newest journeys and one journey's
# readout as console screens (2026-10-31; root_console.css). The STATE /
# TYPE filters accept only the listed values.
class Admin::GridTransitJourneysController < Admin::ApplicationController
  include Admin::DevToolsGate

  before_action :require_dev_tools, only: :force_abandon

  def index
    @state = params[:state].presence_in(GridTransitJourney::STATES)
    @journey_type = params[:journey_type].presence_in(GridTransitJourney::JOURNEY_TYPES)
    @journeys = GridTransitJourney.includes(:grid_hackr, :grid_transit_route, :grid_slipstream_route)
      .order(created_at: :desc)
      .limit(100)

    @journeys = @journeys.where(state: @state) if @state
    @journeys = @journeys.where(journey_type: @journey_type) if @journey_type
  end

  def show
    @journey = GridTransitJourney.includes(
      :grid_hackr, :grid_transit_route, :grid_slipstream_route,
      :current_stop, :current_leg, :origin_room, :destination_room
    ).find(params[:id])
  end

  def force_abandon
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
