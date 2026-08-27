# frozen_string_literal: true

module Grid
  # Single entry point for "run this game command for this hackr" —
  # extracted from Api::GridController#command (Phase 6a) so the JSON API
  # and the Hotwire /grid page can't drift. Handles the room/tutorial
  # bootstrap, parses + executes, publishes room events (JSON + Turbo
  # HTML dual-publish via RoomEventBroadcaster), reloads the hackr, and
  # reports whether the command moved them.
  class CommandRunner
    Result = Struct.new(:output, :event, :room_changed) do
      def clear?
        event && event[:type] == "clear"
      end
    end

    def self.run(hackr, input)
      new(hackr, input).run
    end

    def initialize(hackr, input)
      @hackr = hackr
      @input = input
    end

    def run
      # Ensure hackr has a room (handles stale sessions after DB reset)
      @hackr.ensure_current_room!

      # Start tutorial for hackrs who haven't seen it (handles stale sessions)
      if @hackr.stat("tutorial_active").nil? && @hackr.stat("tutorial_completed").nil?
        tutorial = Grid::TutorialService.new(@hackr)
        tutorial.start!
        hub = tutorial.tutorial_hub_room
        @hackr.update!(current_room: hub) if hub
        unless @hackr.den.present?
          @hackr.grid_items.joins(:grid_item_definition)
            .where(grid_item_definitions: {slug: "den-access-chip"}).destroy_all
        end
      end

      @hackr.touch_activity!

      room_before_id = @hackr.current_room_id

      result = Grid::CommandParser.new(@hackr, @input).execute
      event = result[:event]

      RoomEventBroadcaster.publish(event, hackr: @hackr) if event

      # Reload to get updated current_room
      @hackr.reload

      Result.new(result[:output], event, @hackr.current_room_id != room_before_id)
    end
  end
end
