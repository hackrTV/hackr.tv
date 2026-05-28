# frozen_string_literal: true

module Api
  module Admin
    class WorldEventsController < BaseController
      # POST /api/admin/world_events
      #
      # Publish an event to the World Event Feed. Used by Synthia and
      # other external services for custom announcements.
      #
      # Params:
      #   event_type: (required) One of WorldEvent::EVENT_TYPES
      #   hackr_alias: (optional) Alias to attribute the event to. Defaults to admin hackr.
      #   data: (optional) Hash of event-specific data
      #   message: (optional) Shorthand for data.message when event_type is "manual"
      def create
        event_type = params[:event_type].to_s.strip

        unless WorldEvent::EVENT_TYPES.include?(event_type)
          return render json: {success: false, error: "Invalid event_type. Valid: #{WorldEvent::EVENT_TYPES.join(", ")}"}, status: :unprocessable_entity
        end

        hackr_alias = params[:hackr_alias].presence || @current_admin_hackr.hackr_alias
        data = sanitize_event_data(params[:data]&.to_unsafe_h || {})

        # Shorthand: if event_type is "manual" and message is provided at top level
        if event_type == "manual" && params[:message].present? && data["message"].blank?
          data["message"] = params[:message].to_s.truncate(256)
        end

        event = WorldEventFeed::Publisher.publish(
          event_type: event_type,
          hackr_alias: hackr_alias,
          data: data,
          simulated: false
        )

        if event
          render json: {
            success: true,
            event: WorldEventFeed::Publisher.serialize(event)
          }, status: :created
        else
          render json: {success: false, error: "Failed to publish event"}, status: :internal_server_error
        end
      end

      private

      # Cap string values in the data hash to prevent oversized payloads
      def sanitize_event_data(hash)
        hash.transform_values do |v|
          v.is_a?(String) ? v.truncate(256) : v
        end
      end
    end
  end
end
