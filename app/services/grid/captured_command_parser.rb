# frozen_string_literal: true

module Grid
  # Handles command dispatch when a hackr is captured in a GovCorp facility.
  # Restricts available commands to facility-appropriate actions.
  # The main CommandParser gates into this class when hackr.stat("captured") is true.
  class CapturedCommandParser
    ALLOWED_COMMANDS = %w[
      look l go move north n south s east e west w up u down d out
      stat stats st inventory inv i help ?
      breach br bribe talk examine ex x who clear cls cl say
    ].freeze

    attr_reader :hackr, :input, :parser

    def initialize(hackr, input, parser)
      @hackr = hackr
      @input = input.to_s.strip
      @parser = parser
    end

    def execute
      return {output: "<span style='color: #fbbf24;'>Please enter a command.</span>", event: nil} if input.empty?

      parts = input.split
      command = parts.first&.downcase
      args = parts[1..]

      unless ALLOWED_COMMANDS.include?(command)
        return {output: restricted_message(command), event: nil}
      end

      result = case command
      when "bribe"
        bribe_command(args.join(" "))
      when "help", "?"
        captured_help_command
      else
        # Delegate allowed commands to the main CommandParser
        parser.send(:dispatch_command, command, args)
      end

      result.is_a?(Hash) ? result : {output: result, event: nil}
    end

    private

    def bribe_command(target_name)
      parts = target_name.to_s.strip.split
      confirming = parts.last&.downcase == "confirm"
      mob_name = confirming ? parts[0..-2].join(" ") : parts.join(" ")
      return "<span style='color: #fbbf24;'>Bribe whom? Specify a name.</span>" if mob_name.empty?

      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere.</span>" unless room

      mob = room.grid_mobs.find_by("LOWER(name) = ?", mob_name.downcase)
      return "<span style='color: #f87171;'>You don't see '#{h(mob_name)}' here.</span>" unless mob

      case mob.mob_type
      when "special"
        # Determine if this is an impound clerk or exit agent based on room type
        if room.room_type == "impound"
          bribe_clerk(mob)
        else
          bribe_agent(mob, confirming: confirming)
        end
      else
        "<span style='color: #9ca3af;'>#{h(mob.name)} doesn't seem interested in that.</span>"
      end
    end

    def bribe_clerk(mob)
      records = hackr.grid_impound_records.impounded
      if records.empty?
        return "<span style='color: #9ca3af;'>#{h(mob.name)} checks the system. No impounded items found under your ID.</span>"
      end

      # Recover impound sets one at a time. If funds run out mid-loop,
      # show what was recovered + the failure for the remaining set.
      output = []
      records.each do |record|
        result = Grid::ImpoundService.recover_gear!(hackr: hackr, impound_record: record)
        output << result.display
      rescue Grid::ImpoundService::InsufficientBalance => e
        output << "<span style='color: #f87171;'>#{h(e.message)}</span>"
        remaining = hackr.grid_impound_records.impounded.count
        output << "<span style='color: #9ca3af;'>#{remaining} impound set(s) still held.</span>" if remaining > 0
        break
      end
      output.join("\n")
    end

    def bribe_agent(mob, confirming: false)
      fee = Grid::ContainmentService.compute_exit_bribe(hackr)
      impound_count = hackr.grid_impound_records.impounded.count

      if confirming
        result = Grid::ContainmentService.bribe_exit!(hackr: hackr)
        return result.display
      end

      # Show fee preview
      output = []
      output << "<span style='color: #fbbf24;'>#{h(mob.name)} reviews your file.</span>"
      gear_note = if impound_count > 0
        "#{impound_count} impound set(s) will be forfeited."
      else
        "No impounded gear on file."
      end
      output << "<span style='color: #fbbf24;'>Resolution fee: #{fee} CRED. #{gear_note}</span>"
      output << "<span style='color: #9ca3af;'>Type 'bribe #{mob.name.downcase} confirm' to proceed.</span>"
      output.join("\n")
    rescue Grid::ContainmentService::InsufficientFunds => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    end

    def captured_help_command
      output = []
      output << "<span style='color: #ef4444; font-weight: bold;'>══ GovCorp FACILITY — RESTRICTED COMMANDS ══</span>"
      output << ""
      output << "<span style='color: #fbbf24;'>look</span>                  <span style='color: #9ca3af;'>Look around</span>"
      output << "<span style='color: #fbbf24;'>go &lt;direction&gt;</span>        <span style='color: #9ca3af;'>Move (increases alert)</span>"
      output << "<span style='color: #fbbf24;'>breach</span>                <span style='color: #9ca3af;'>Initiate BREACH encounter</span>"
      output << "<span style='color: #fbbf24;'>bribe &lt;npc&gt;</span>           <span style='color: #9ca3af;'>Negotiate with facility staff</span>"
      output << "<span style='color: #fbbf24;'>talk &lt;npc&gt;</span>            <span style='color: #9ca3af;'>Talk to someone</span>"
      output << "<span style='color: #fbbf24;'>examine &lt;target&gt;</span>      <span style='color: #9ca3af;'>Examine something</span>"
      output << "<span style='color: #fbbf24;'>stat</span>                  <span style='color: #9ca3af;'>View your stats</span>"
      output << "<span style='color: #fbbf24;'>inventory</span>             <span style='color: #9ca3af;'>Check inventory</span>"
      output << "<span style='color: #fbbf24;'>who</span>                   <span style='color: #9ca3af;'>See who's here</span>"
      output << ""
      output << "<span style='color: #ef4444;'>All other commands restricted by GovCorp facility protocol.</span>"
      output.join("\n")
    end

    def restricted_message(command)
      "<span style='color: #f87171;'>GovCorp facility restrictions in effect. '#{h(command)}' unavailable. Type <span style='color: #22d3ee;'>help</span> for available commands.</span>"
    end

    def h(text)
      ERB::Util.html_escape(text.to_s)
    end
  end
end
