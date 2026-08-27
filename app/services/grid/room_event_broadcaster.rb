# frozen_string_literal: true

module Grid
  # Room event fan-out (Phase 6a dual-publish). The JSON broadcasts feed
  # GridChannel/ZoneChannel subscribers (the React tactical page until
  # 6b–6c; payloads unchanged); the Turbo Stream broadcasts append
  # rendered terminal lines to per-room "grid_room_html" streams for the
  # Hotwire /grid page. Movement renders per-room perspectives server-side
  # (departure line to the old room, arrival line to the new room) — the
  # SPA computed that client-side from from/to ids.
  class RoomEventBroadcaster
    # GridGamePage.tsx handleEvent colors.
    COLORS = {
      movement: "#22d3ee",
      take: "#fbbf24",
      drop: "#fbbf24",
      system_broadcast: "#f87171"
    }.freeze

    OPPOSITE_DIRECTIONS = {
      "north" => "south", "south" => "north",
      "east" => "west", "west" => "east",
      "northeast" => "southwest", "southwest" => "northeast",
      "northwest" => "southeast", "southeast" => "northwest",
      "up" => "below", "down" => "above"
    }.freeze

    def self.publish(event, hackr:)
      new(event, hackr).publish
    end

    # Admin "broadcast to all rooms" tool (system_broadcast type).
    def self.publish_system_broadcast(room, event)
      GridChannel.broadcast_to(room, event)
      broadcast_line(room,
        partial: "grid/event_line",
        locals: {color: COLORS[:system_broadcast], bold: true, timestamp: Time.current,
                 text: event[:message]})
    end

    def initialize(event, hackr)
      @event = event
      @hackr = hackr
    end

    def publish
      case @event[:type]
      when "movement"
        from_room = GridRoom.find_by(id: @event[:from_room_id])
        to_room = GridRoom.find_by(id: @event[:to_room_id])
        publish_movement(from_room, to_room)
        publish_zone_presence(from_room, to_room)
      when "say"
        room = @hackr.current_room
        return unless room
        GridChannel.broadcast_to(room, @event)
        self.class.broadcast_line(room,
          partial: "grid/say_line",
          locals: {hackr_alias: @event[:hackr_alias], message: @event[:message]})
      when "take", "drop"
        room = @hackr.current_room
        return unless room
        GridChannel.broadcast_to(room, @event)
        verb = (@event[:type] == "take") ? "takes" : "drops"
        self.class.broadcast_line(room,
          partial: "grid/event_line",
          locals: {color: COLORS[@event[:type].to_sym], bold: false, timestamp: Time.current,
                   text: "#{@event[:hackr_alias]} #{verb} the #{@event[:item_name]}."})
      end
    end

    def self.broadcast_line(room, partial:, locals:)
      Turbo::StreamsChannel.broadcast_append_to(
        ["grid_room_html", room.id],
        target: "grid-log",
        partial: partial,
        locals: locals
      )
    end

    private

    def publish_movement(from_room, to_room)
      now = Time.current
      if from_room
        GridChannel.broadcast_to(from_room, @event)
        self.class.broadcast_line(from_room,
          partial: "grid/event_line",
          locals: {color: COLORS[:movement], bold: false, timestamp: now,
                   text: "#{@event[:hackr_alias]} leaves to the #{@event[:direction]}."})
      end
      if to_room
        GridChannel.broadcast_to(to_room, @event)
        arrival = OPPOSITE_DIRECTIONS.fetch(@event[:direction].to_s, "somewhere")
        self.class.broadcast_line(to_room,
          partial: "grid/event_line",
          locals: {color: COLORS[:movement], bold: false, timestamp: now,
                   text: "#{@event[:hackr_alias]} enters from the #{arrival}."})
      end
    end

    # Zone-level presence broadcast for the tactical map (JSON only —
    # the map goes Hotwire in 6c).
    def publish_zone_presence(from_room, to_room)
      zone_ids = [from_room&.grid_zone_id, to_room&.grid_zone_id].compact.uniq
      presence_event = @event.merge(type: "presence_update")
      zone_ids.each do |zone_id|
        ActionCable.server.broadcast(ZoneChannel.stream_name_for(zone_id), presence_event)
      end
    end
  end
end
