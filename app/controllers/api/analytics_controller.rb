# frozen_string_literal: true

module Api
  class AnalyticsController < ApplicationController
    # sendBeacon does not send CSRF tokens
    protect_from_forgery with: :null_session

    MAX_BATCH_SIZE = 50

    # POST /api/analytics/events
    def create_batch
      events = params[:events]

      unless events.is_a?(Array) && events.size.between?(1, MAX_BATCH_SIZE)
        return head :bad_request
      end

      now = Time.current
      rows = events.first(MAX_BATCH_SIZE).filter_map do |e|
        event_type = e[:event_type].to_s
        next unless AnalyticsEvent::EVENT_TYPES.include?(event_type)

        {
          event_type: event_type,
          event_name: e[:event_name].to_s.first(100),
          hackr_id: current_hackr&.id,
          session_id: e[:session_id].to_s.first(36),
          properties: (e[:properties].respond_to?(:to_unsafe_h) ? e[:properties].to_unsafe_h.to_json : e[:properties].to_s).truncate(2000),
          created_at: now
        }
      end

      AnalyticsEvent.insert_all(rows) if rows.any?

      head :no_content
    end
  end
end
