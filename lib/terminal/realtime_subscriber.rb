# frozen_string_literal: true

require "json"

module Terminal
  # Real-time subscriber for terminal sessions
  # Subscribes directly to Action Cable pubsub for instant updates
  class RealtimeSubscriber
    attr_reader :session

    def initialize(session)
      @session = session
      @wire_callback = nil
      @grid_callback = nil
      @wire_subscription = nil
      @grid_subscription = nil
      @current_room_stream = nil
      @mutex = Mutex.new
    end

    # Register a callback for wire events
    # @param block [Proc] Callback to invoke with new pulse data
    def on_wire(&block)
      @wire_callback = block
      subscribe_wire if block
    end

    # Register a callback for grid events
    # @param block [Proc] Callback to invoke with event data
    def on_grid(&block)
      @grid_callback = block
    end

    # Start monitoring a specific room for grid events
    # @param room_id [Integer] Room ID to monitor
    def monitor_room(room_id)
      room = GridRoom.find_by(id: room_id)
      return unless room

      @mutex.synchronize do
        # Unsubscribe from old room if different
        unsubscribe_grid if @current_room_stream

        # Get the stream name for this room
        @current_room_stream = GridChannel.broadcasting_for(room)

        # Subscribe to the new room
        subscribe_grid if @grid_callback
      end
    end

    # Stop all subscriptions
    def stop
      unsubscribe_wire
      unsubscribe_grid
    end

    # Clear all callbacks and unsubscribe
    def clear_callbacks
      @wire_callback = nil
      @grid_callback = nil
      unsubscribe_wire
      unsubscribe_grid
    end

    # Check if actively subscribed (for compatibility)
    def running?
      @wire_subscription.present? || @grid_subscription.present?
    end

    # No-op for compatibility with polling interface
    def start
      # Subscriptions are set up when callbacks are registered
    end

    private

    def pubsub
      ActionCable.server.pubsub
    end

    def subscribe_wire
      return if @wire_subscription

      @wire_subscription = ->(message) { handle_wire_message(message) }

      pubsub.subscribe("pulse_wire", @wire_subscription)
      Rails.logger.info "Terminal: Subscribed to pulse_wire"
    end

    def unsubscribe_wire
      return unless @wire_subscription

      pubsub.unsubscribe("pulse_wire", @wire_subscription)
      @wire_subscription = nil
      Rails.logger.info "Terminal: Unsubscribed from pulse_wire"
    end

    def subscribe_grid
      return if @grid_subscription || @current_room_stream.blank?

      @grid_subscription = ->(message) { handle_grid_message(message) }

      pubsub.subscribe(@current_room_stream, @grid_subscription)
      Rails.logger.info "Terminal: Subscribed to #{@current_room_stream}"
    end

    def unsubscribe_grid
      return unless @grid_subscription && @current_room_stream

      pubsub.unsubscribe(@current_room_stream, @grid_subscription)
      @grid_subscription = nil
      @current_room_stream = nil
      Rails.logger.info "Terminal: Unsubscribed from grid room"
    end

    def handle_wire_message(message)
      return unless @wire_callback

      begin
        data = JSON.parse(message, symbolize_names: true)

        # Only handle new_pulse events
        return unless data[:type] == "new_pulse" && data[:pulse]

        pulse_data = data[:pulse]

        # Skip our own pulses
        if session.hackr && pulse_data[:grid_hackr]
          return if pulse_data[:grid_hackr][:id] == session.hackr.id
        end

        event = {
          type: "new_pulse",
          id: pulse_data[:id],
          hackr_alias: pulse_data[:grid_hackr]&.dig(:hackr_alias) || "Unknown",
          content: pulse_data[:content],
          pulsed_at: pulse_data[:pulsed_at]
        }

        @wire_callback.call(event)
      rescue JSON::ParserError => e
        Rails.logger.error "Terminal: Failed to parse wire message: #{e.message}"
      rescue => e
        Rails.logger.error "Terminal: Error handling wire message: #{e.message}"
      end
    end

    def handle_grid_message(message)
      return unless @grid_callback

      begin
        data = JSON.parse(message, symbolize_names: true)

        # Skip our own events
        if session.hackr && data[:hackr_id]
          return if data[:hackr_id] == session.hackr.id
        end

        # Format event based on type
        event = case data[:type]
        when "say"
          {
            type: "say",
            hackr_alias: data[:hackr_alias],
            content: data[:message]
          }
        when "movement"
          direction = data[:direction]
          if data[:to_room_id] && session.hackr&.current_room_id == data[:to_room_id]
            # Someone arrived
            {
              type: "arrival",
              hackr_alias: data[:hackr_alias],
              direction: opposite_direction(direction)
            }
          elsif data[:from_room_id] && session.hackr&.current_room_id == data[:from_room_id]
            # Someone left
            {
              type: "departure",
              hackr_alias: data[:hackr_alias],
              direction: direction
            }
          end
        when "take", "drop"
          {
            type: data[:type],
            hackr_alias: data[:hackr_alias],
            item: data[:item_name]
          }
        end

        @grid_callback.call(event) if event
      rescue JSON::ParserError => e
        Rails.logger.error "Terminal: Failed to parse grid message: #{e.message}"
      rescue => e
        Rails.logger.error "Terminal: Error handling grid message: #{e.message}"
      end
    end

    def opposite_direction(direction)
      opposites = {
        "north" => "south", "south" => "north",
        "east" => "west", "west" => "east",
        "up" => "below", "down" => "above",
        "in" => "outside", "out" => "inside"
      }
      opposites[direction] || direction
    end
  end
end
