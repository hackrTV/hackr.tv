# frozen_string_literal: true

module Grid
  # Handles ambient (random) encounter generation on room entry.
  # Called from CommandParser#go_command when a hackr enters a room
  # in a zone with danger_level > 0.
  class BreachGeneratorService
    AmbientResult = Data.define(:display, :ejected)

    def self.ambient_check!(hackr:, room:)
      new(hackr, room).ambient_check!
    end

    def initialize(hackr, room)
      @hackr = hackr
      @room = room
    end

    # Returns AmbientResult if an encounter triggered, nil otherwise.
    def ambient_check!
      zone = @room.grid_zone
      return nil if zone.danger_level == 0
      return nil if @hackr.in_breach?

      # Roll against danger level: danger_level * 5% chance per room entry
      return nil unless rand < (zone.danger_level * 0.05)

      # Find a matching ambient template for this zone
      template = find_ambient_template(zone)
      return nil unless template

      # No DECK equipped → auto-fail at tier 1 (vitals drain + eject)
      unless @hackr.equipped_deck
        return auto_fail_no_deck!(template)
      end

      # Start the ambient BREACH
      start_ambient!(template)
    end

    private

    def find_ambient_template(zone)
      templates = GridBreachTemplate.published.ambient
        .where("danger_level_min <= ?", zone.danger_level)
        .where("min_clearance <= ?", @hackr.stat("clearance"))
        .to_a

      # Filter by zone_slugs (empty = any zone)
      templates.select! { |t| t.matches_zone?(zone) }

      templates.sample
    end

    def start_ambient!(template)
      result = Grid::BreachService.start_ambient!(hackr: @hackr, template: template)

      display = []
      display << ""
      display << "<span style='color: #ef4444; font-weight: bold;'>\u26a0 AMBIENT BREACH \u2014 you've been detected!</span>"
      display << ""
      display << result.display
      display << ""
      display << "<span style='color: #6b7280;'>Type 'help' for BREACH commands.</span>"

      AmbientResult.new(display: display.join("\n"), ejected: false)
    rescue Grid::BreachService::AlreadyInBreach
      nil # Race condition — another breach started between check and start
    end

    def auto_fail_no_deck!(template)
      eject_room_id = nil
      ejected = false

      ActiveRecord::Base.transaction do
        @hackr.lock!

        # Tier 1 failure: vitals drain
        @hackr.adjust_vital!("energy", -20)
        @hackr.adjust_vital!("psyche", -20)

        # Eject to zone entry room (if available)
        eject_room_id = @hackr.zone_entry_room_id
        if eject_room_id && eject_room_id != @hackr.current_room_id
          @hackr.update!(current_room_id: eject_room_id)
          ejected = true
        end
      end

      display = []
      display << ""
      display << "<span style='color: #ef4444; font-weight: bold;'>\u26a0 AMBIENT BREACH \u2014 #{ERB::Util.html_escape(template.name)}</span>"
      display << "<span style='color: #f87171;'>No DECK equipped \u2014 system scan overwhelms your unshielded neural link.</span>"
      display << ""
      display << "<span style='color: #f87171;'>ENERGY -20 | PSYCHE -20</span>"
      if ejected
        eject_room = GridRoom.find_by(id: eject_room_id)
        display << "<span style='color: #f87171;'>Ejected to #{ERB::Util.html_escape(eject_room&.name || "unknown")}.</span>"
      end
      display << "<span style='color: #6b7280;'>Equip a DECK to survive ambient encounters.</span>"

      AmbientResult.new(display: display.join("\n"), ejected: ejected)
    end
  end
end
