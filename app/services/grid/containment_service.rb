# frozen_string_literal: true

module Grid
  # Manages the GovCorp Perception Alignment Center lifecycle:
  # capture → alert tracking → escape (Sally Port or agent bribe).
  # All formula values are named constants for future admin abstraction.
  class ContainmentService
    CaptureResult = Data.define(:hackr, :containment_room, :impound_result, :display)
    AlertResult = Data.define(:hackr, :alert_level, :caught, :display)
    EscapeResult = Data.define(:hackr, :destination_room, :display)
    BribeExitResult = Data.define(:hackr, :fee_paid, :forfeit_results, :destination_room, :display)

    class AlreadyCaptured < StandardError; end
    class NotCaptured < StandardError; end
    class NotAtFacility < StandardError; end
    class InsufficientFunds < StandardError; end
    class NoContainmentRoom < StandardError; end

    # Alert system constants
    ALERT_PER_MOVE = 12
    ALERT_BREACH_REDUCTION = 25
    ALERT_THRESHOLD = 100

    # Agent bribe (exit facility, forfeit all gear)
    EXIT_BRIBE_BASE_FEE = 250
    EXIT_BRIBE_CL_MULT = 15

    # Failure tier capture chances (detection-overflow only)
    STANDARD_CAPTURE_CHANCE = 0.25
    ADVANCED_CAPTURE_CHANCE = 0.50

    # Chance that advanced-tier capture also impounds gear (separate from capture chance)
    ADVANCED_IMPOUND_CHANCE = 0.50

    # Room types that don't increment alert
    SAFE_ROOM_TYPES = %w[containment impound].freeze

    def self.capture!(hackr:, breach:, impound: false)
      new(hackr).capture!(breach, impound: impound)
    end

    def self.alert_increment!(hackr:)
      new(hackr).alert_increment!
    end

    def self.alert_reduce!(hackr:, amount: ALERT_BREACH_REDUCTION)
      new(hackr).alert_reduce!(amount)
    end

    def self.escape_facility!(hackr:, via: :sally_port)
      new(hackr).escape_facility!(via: via)
    end

    def self.bribe_exit!(hackr:)
      new(hackr).bribe_exit!
    end

    def self.compute_exit_bribe(hackr)
      (EXIT_BRIBE_BASE_FEE + hackr.stat("clearance") * EXIT_BRIBE_CL_MULT).to_i
    end

    def self.captured?(hackr)
      hackr.stat("captured") == true
    end

    # Render alert bar for look_command HUD.
    def self.render_alert_bar(level)
      width = 20
      filled = [(level.to_f / ALERT_THRESHOLD * width).round, width].min
      empty = width - filled
      color = if level >= 70 then "#f87171"
      elsif level >= 40 then "#fbbf24"
      else "#34d399"
      end
      "<span style='color: #9ca3af;'>\u26a0 FACILITY ALERT:</span> " \
        "<span style='color: #{color};'>#{"█" * filled}#{"░" * empty}</span> " \
        "<span style='color: #{color};'>#{level}%</span>"
    end

    def initialize(hackr)
      @hackr = hackr
    end

    # Capture a hackr and teleport to containment cell.
    # Called from BreachService#resolve_failure! for tiers 5+6.
    def capture!(breach, impound: false)
      raise AlreadyCaptured, "Already in GovCorp custody." if self.class.captured?(@hackr)

      containment_room = find_containment_room
      raise NoContainmentRoom, "No containment facility available." unless containment_room

      impound_result = nil

      ActiveRecord::Base.transaction do
        @hackr.lock!

        @hackr.set_stat!("captured", true)
        @hackr.set_stat!("captured_origin_room_id", @hackr.current_room_id)
        @hackr.set_stat!("facility_alert_level", 0)
        @hackr.update!(current_room_id: containment_room.id)
      end

      # Impound gear outside main transaction (ImpoundService has its own)
      if impound
        begin
          impound_result = Grid::ImpoundService.impound_gear!(hackr: @hackr, breach: breach)
        rescue Grid::ImpoundService::NoEquippedGear
          # Nothing to impound — captured without gear
        rescue => e
          Rails.logger.error("[ContainmentService] impound_gear! failed: #{e.message} — hackr #{@hackr.id} captured without impound")
          # Gear stays equipped rather than being orphaned
        end
      end

      display = render_capture(containment_room, impound_result)
      CaptureResult.new(
        hackr: @hackr,
        containment_room: containment_room,
        impound_result: impound_result,
        display: display
      )
    end

    # Increment alert on room move within facility. Returns AlertResult.
    # Called from go_command when captured.
    def alert_increment!
      raise NotCaptured, "Not in custody." unless self.class.captured?(@hackr)

      room = @hackr.current_room
      # Safe rooms don't increment
      if room && SAFE_ROOM_TYPES.include?(room.room_type)
        level = @hackr.stat("facility_alert_level").to_i
        return AlertResult.new(hackr: @hackr, alert_level: level, caught: false, display: nil)
      end

      caught = false
      level = 0

      ActiveRecord::Base.transaction do
        @hackr.lock!

        level = @hackr.stat("facility_alert_level").to_i + ALERT_PER_MOVE
        level = [level, ALERT_THRESHOLD].min
        @hackr.set_stat!("facility_alert_level", level)

        if level >= ALERT_THRESHOLD
          caught = true
          alert_catch!
        end
      end

      display = if caught
        render_caught
      else
        self.class.render_alert_bar(level)
      end

      AlertResult.new(hackr: @hackr, alert_level: level, caught: caught, display: display)
    end

    # Reduce alert after successful BREACH in facility.
    def alert_reduce!(amount)
      return unless self.class.captured?(@hackr)

      level = @hackr.stat("facility_alert_level").to_i
      new_level = [level - amount, 0].max
      @hackr.set_stat!("facility_alert_level", new_level)
    end

    # Exit facility via Sally Port or after cell BREACH.
    # `via` determines which exit room is used.
    def escape_facility!(via: :sally_port)
      raise NotCaptured, "Not in custody." unless self.class.captured?(@hackr)

      region = find_current_region
      destination = case via
      when :sally_port
        region&.facility_exit_room
      when :bribe
        region&.facility_bribe_exit_room
      end
      destination ||= fallback_exit_room

      ActiveRecord::Base.transaction do
        @hackr.lock!
        @hackr.set_stat!("captured", nil)
        @hackr.set_stat!("captured_origin_room_id", nil)
        @hackr.set_stat!("facility_alert_level", nil)
        @hackr.update!(current_room_id: destination.id)
      end

      display = render_escape(destination)
      EscapeResult.new(hackr: @hackr, destination_room: destination, display: display)
    end

    # Bribe a GovCorp agent to exit facility. Forfeits ALL impounded gear.
    def bribe_exit!
      raise NotCaptured, "Not in custody." unless self.class.captured?(@hackr)

      fee = self.class.compute_exit_bribe(@hackr)
      cache = @hackr.default_cache
      raise InsufficientFunds, "Need #{fee} CRED. You have #{cache&.balance || 0}." unless cache&.balance.to_i >= fee

      # Pay bribe FIRST — gear destruction is irreversible, so payment must succeed first.
      burn_amt = (fee * EconomyConfig::SHOP_BURN_RATIO).floor
      recycle_amt = fee - burn_amt
      Grid::TransactionService.burn!(from_cache: cache, amount: burn_amt, memo: "GovCorp compliance resolution") if burn_amt > 0
      Grid::TransactionService.recycle!(from_cache: cache, amount: recycle_amt, memo: "GovCorp compliance resolution") if recycle_amt > 0

      # Forfeit all impounded gear sets (payment already succeeded)
      forfeit_results = []
      @hackr.grid_impound_records.impounded.each do |record|
        result = Grid::ImpoundService.forfeit!(impound_record: record)
        forfeit_results << result
      end

      # Exit facility
      escape_result = escape_facility!(via: :bribe)

      display = render_bribe_exit(fee, forfeit_results, escape_result.destination_room)
      BribeExitResult.new(
        hackr: @hackr,
        fee_paid: fee,
        forfeit_results: forfeit_results,
        destination_room: escape_result.destination_room,
        display: display
      )
    end

    private

    # Return to containment cell when alert threshold reached.
    def alert_catch!
      containment_room = find_containment_room
      return unless containment_room

      @hackr.set_stat!("facility_alert_level", 0)
      @hackr.update!(current_room_id: containment_room.id)
    end

    def find_containment_room
      region = find_current_region
      region&.containment_room
    end

    def find_current_region
      @hackr.current_room&.grid_zone&.grid_region
    end

    def fallback_exit_room
      origin_id = @hackr.stat("captured_origin_room_id")
      GridRoom.find_by(id: origin_id) || @hackr.current_room
    end

    # --- Renderers ---

    def render_capture(containment_room, impound_result)
      h = method(:h)
      separator = Grid::BreachRenderer::SEPARATOR
      border = "<span style='color: #ef4444;'>\u2551</span>"
      lines = []
      lines << ""
      lines << "<span style='color: #ef4444; font-weight: bold;'>\u2554#{separator}\u2557</span>"
      lines << "<span style='color: #ef4444; font-weight: bold;'>\u2551  \u26a0 DETAINED \u2014 GovCorp Perception Alignment Center       \u2551</span>"
      lines << "<span style='color: #ef4444; font-weight: bold;'>\u2560#{separator}\u2563</span>"
      lines << "#{border}  <span style='color: #d0d0d0;'>GovCorp countermeasures have locked your position.</span>"
      lines << "#{border}  <span style='color: #d0d0d0;'>Neural trace confirmed. Physical extraction complete.</span>"
      lines << border

      zone_name = containment_room.grid_zone&.name || "Unknown"
      lines << "#{border}  <span style='color: #9ca3af;'>Location: #{h.call(zone_name)} \u2014 #{h.call(containment_room.name)}</span>"

      if impound_result
        lines << border
        lines << "#{border}  <span style='color: #ef4444; font-weight: bold;'>All equipped gear has been confiscated.</span>"
        lines << "#{border}  <span style='color: #fbbf24;'>Recovery bribe: #{impound_result.bribe_cost} CRED</span>"
      end

      lines << border
      lines << "#{border}  <span style='color: #9ca3af;'>The cell door is BREACH-locked. Solve the gates to escape.</span>"
      lines << "#{border}  <span style='color: #6b7280;'>Type 'breach' to attempt the containment seal.</span>"
      lines << "<span style='color: #ef4444; font-weight: bold;'>\u255a#{separator}\u255d</span>"
      lines.join("\n")
    end

    def render_caught
      separator = Grid::BreachRenderer::SEPARATOR
      border = "<span style='color: #ef4444;'>\u2551</span>"
      lines = []
      lines << ""
      lines << "<span style='color: #ef4444; font-weight: bold;'>\u2554#{separator}\u2557</span>"
      lines << "<span style='color: #ef4444; font-weight: bold;'>\u2551  APPREHENDED                                               \u2551</span>"
      lines << "<span style='color: #ef4444; font-weight: bold;'>\u2560#{separator}\u2563</span>"
      lines << "#{border}  <span style='color: #d0d0d0;'>GovCorp security detected your movement.</span>"
      lines << "#{border}  <span style='color: #d0d0d0;'>Returned to containment. Alert level reset.</span>"
      lines << border
      lines << "#{border}  <span style='color: #9ca3af;'>The cell door is BREACH-locked. Try again.</span>"
      lines << "<span style='color: #ef4444; font-weight: bold;'>\u255a#{separator}\u255d</span>"
      lines.join("\n")
    end

    def render_escape(destination)
      separator = Grid::BreachRenderer::SEPARATOR
      border = "<span style='color: #34d399;'>\u2551</span>"
      lines = []
      lines << ""
      lines << "<span style='color: #34d399; font-weight: bold;'>\u2554#{separator}\u2557</span>"
      lines << "<span style='color: #34d399; font-weight: bold;'>\u2551  EXTRACTION SUCCESSFUL                                      \u2551</span>"
      lines << "<span style='color: #34d399; font-weight: bold;'>\u2560#{separator}\u2563</span>"
      lines << "#{border}  <span style='color: #d0d0d0;'>Facility containment cleared. GovCorp trace broken.</span>"
      zone_name = destination.grid_zone&.name || "Unknown"
      lines << "#{border}  <span style='color: #9ca3af;'>Location: #{h(zone_name)}</span>"
      lines << "<span style='color: #34d399; font-weight: bold;'>\u255a#{separator}\u255d</span>"
      lines.join("\n")
    end

    def render_bribe_exit(fee, forfeit_results, destination)
      separator = Grid::BreachRenderer::SEPARATOR
      border = "<span style='color: #fbbf24;'>\u2551</span>"
      total_items = forfeit_results.sum(&:items_destroyed)
      lines = []
      lines << ""
      lines << "<span style='color: #fbbf24; font-weight: bold;'>\u2554#{separator}\u2557</span>"
      lines << "<span style='color: #fbbf24; font-weight: bold;'>\u2551  COMPLIANCE RESOLUTION \u2014 Administrative Release             \u2551</span>"
      lines << "<span style='color: #fbbf24; font-weight: bold;'>\u2560#{separator}\u2563</span>"
      lines << "#{border}  <span style='color: #fbbf24;'>Resolution fee: #{fee} CRED</span>"
      if total_items > 0
        lines << "#{border}  <span style='color: #ef4444;'>#{total_items} impounded item(s) forfeited to GovCorp.</span>"
      end
      lines << border
      zone_name = destination.grid_zone&.name || "Unknown"
      lines << "#{border}  <span style='color: #d0d0d0;'>Escorted to #{h(zone_name)}.</span>"
      lines << "#{border}  <span style='color: #9ca3af;'>Your record has been flagged as 'administratively resolved.'</span>"
      lines << "<span style='color: #fbbf24; font-weight: bold;'>\u255a#{separator}\u255d</span>"
      lines.join("\n")
    end

    def h(text)
      ERB::Util.html_escape(text.to_s)
    end
  end
end
