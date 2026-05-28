# frozen_string_literal: true

module Api
  class WorldEventsController < ApplicationController
    # GET /api/world_events
    # Public endpoint for initial feed hydration.
    def index
      limit = (params[:limit] || 50).to_i.clamp(1, 100)
      events = WorldEvent.recent.limit(limit).to_a.reverse

      render json: {
        events: events.map { |e| WorldEventFeed::Publisher.serialize(e) }
      }
    end
  end
end
