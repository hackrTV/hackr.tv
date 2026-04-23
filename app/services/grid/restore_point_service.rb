# frozen_string_literal: true

module Grid
  # GovCorp RestorePoint™ — emergency medical service for hackrs
  # who reach HEALTH 0. Respawns at the regional RestorePoint™ facility
  # and assesses a CRED fee (deducted from cache or incurred as debt).
  #
  # Design: GTA-style. You wake up, money gone, free to leave.
  # No lock mechanic. The fee IS the punishment.
  class RestorePointService
    BASE_FEE = 50
    FEE_PER_CLEARANCE = 5
    HEALTH_RESTORE_FRACTION = 0.25

    AdmitResult = Data.define(:hackr, :fee_amount, :paid, :debt_incurred,
      :total_debt, :destination_room, :health_restored, :display)

    # Admit a hackr to the nearest RestorePoint™.
    # Called when HEALTH reaches 0 during BREACH (or any future context).
    def self.admit!(hackr)
      new(hackr).admit!
    end

    def initialize(hackr)
      @hackr = hackr
    end

    def admit!
      fee = compute_fee
      destination = find_restore_point

      # Assess fee (pay from cache, remainder becomes debt)
      # Done outside the state transaction — DebtService.assess! calls
      # TransactionService.burn! which has its own LEDGER_MUTEX.
      debt_result = Grid::DebtService.assess!(
        hackr: @hackr,
        amount: fee,
        memo: "RestorePoint\u2122 recovery fee"
      )

      # Restore health + move in a single transaction
      max_health = @hackr.effective_max("health")
      restored_to = (max_health * HEALTH_RESTORE_FRACTION).ceil

      ActiveRecord::Base.transaction do
        @hackr.lock!
        @hackr.set_stat!("health", restored_to)

        if destination && destination.id != @hackr.current_room_id
          @hackr.update!(current_room_id: destination.id)
        end
      end

      display = render_admission(fee, debt_result, destination, restored_to)

      AdmitResult.new(
        hackr: @hackr,
        fee_amount: fee,
        paid: debt_result[:paid],
        debt_incurred: debt_result[:debt_incurred],
        total_debt: debt_result[:total_debt],
        destination_room: destination,
        health_restored: restored_to,
        display: display
      )
    end

    private

    def compute_fee
      clearance = @hackr.stat("clearance")
      BASE_FEE + (clearance * FEE_PER_CLEARANCE)
    end

    def find_restore_point
      # Find RestorePoint™ in current region
      current_room = @hackr.current_room
      return current_room unless current_room

      region = current_room.grid_zone&.grid_region
      return fallback_room if region.nil?

      # Use region's designated hospital room
      if region.hospital_room_id.present?
        return region.hospital_room
      end

      # Fallback: zone entry room
      fallback_room
    end

    def fallback_room
      room_id = @hackr.zone_entry_room_id || @hackr.current_room_id
      GridRoom.find_by(id: room_id) || @hackr.current_room
    end

    def render_admission(fee, debt_result, destination, restored_to)
      separator = Grid::BreachRenderer::SEPARATOR

      lines = []
      lines << ""
      lines << "<span style='color: #f87171; font-weight: bold;'>\u2554#{separator}\u2557</span>"
      lines << "<span style='color: #f87171; font-weight: bold;'>\u2551  \u26a0 RESTOREPOINT\u2122 :: GovCorp Emergency Services              \u2551</span>"
      lines << "<span style='color: #f87171; font-weight: bold;'>\u2560#{separator}\u2563</span>"
      lines << "<span style='color: #f87171;'>\u2551</span>  <span style='color: #d0d0d0;'>Neural link severed. Emergency recovery engaged.</span>"
      lines << "<span style='color: #f87171;'>\u2551</span>"
      lines << "<span style='color: #f87171;'>\u2551</span>  <span style='color: #fbbf24;'>Recovery fee assessed:</span> <span style='color: #f87171;'>#{fee} CRED</span>"

      border = "<span style='color: #f87171;'>\u2551</span>"

      if debt_result[:debt_incurred] <= 0
        # Full payment from cache
        lines << "#{border}  <span style='color: #9ca3af;'>Deducted from cache. Paid in full.</span>"
      elsif debt_result[:paid] > 0
        # Partial payment
        lines << "#{border}  <span style='color: #9ca3af;'>Cache balance insufficient. #{debt_result[:paid]} CRED deducted.</span>"
        lines << "#{border}  <span style='color: #ef4444;'>GovCorp debt incurred: #{debt_result[:debt_incurred]} CRED</span>"
        lines << "#{border}  <span style='color: #ef4444;'>\u26a0 CRED income garnished at 50% until debt cleared.</span>"
      else
        # No funds at all
        lines << "#{border}  <span style='color: #ef4444;'>No funds available. Full debt incurred: #{fee} CRED</span>"
        lines << "#{border}  <span style='color: #ef4444;'>\u26a0 CRED income garnished at 50% until debt cleared.</span>"
      end

      if debt_result[:total_debt] > 0
        lines << "#{border}  <span style='color: #ef4444;'>Total GovCorp debt: #{debt_result[:total_debt]} CRED</span>"
      end

      lines << border
      lines << "#{border}  <span style='color: #34d399;'>HEALTH restored to #{restored_to}.</span>"

      if destination
        zone_name = destination.grid_zone&.name || "Unknown"
        lines << "#{border}  <span style='color: #9ca3af;'>Location: RestorePoint\u2122 \u2014 #{ERB::Util.html_escape(zone_name)}</span>"
      end

      lines << "<span style='color: #f87171; font-weight: bold;'>\u255a#{separator}\u255d</span>"
      lines.join("\n")
    end
  end
end
