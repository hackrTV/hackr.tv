# frozen_string_literal: true

module Grid
  # Handles all command dispatch when a hackr is in an active BREACH encounter.
  # The main CommandParser gates into this class at the top of #execute.
  class BreachCommandParser
    attr_reader :hackr, :input, :breach

    def initialize(hackr, input, breach)
      @hackr = hackr
      @input = input.to_s.strip
      @breach = breach
    end

    def execute
      return {output: "<span style='color: #fbbf24;'>Please enter a command.</span>", event: nil} if input.empty?

      parts = input.split
      command = parts.first&.downcase
      args = parts[1..]

      result = case command
      when "exec", "sh"
        exec_command(args)
      when "analyze", "an"
        analyze_command(args.first)
      when "reroute", "rr"
        reroute_command(args.first)
      when "jackout", "jo"
        jackout_command
      when "status", "st"
        status_command
      when "deck", "dk"
        deck_command
      when "help", "?"
        help_command
      else
        blocked_command(command)
      end

      result.is_a?(Hash) ? result : {output: result, event: nil}
    end

    private

    def exec_command(args)
      if args.nil? || args.length < 2
        return "<span style='color: #fbbf24;'>Usage: exec &lt;program&gt; &lt;target#&gt;</span>"
      end

      target_str = args.last
      program_name = args[0..-2].join(" ")

      target_position = parse_target(target_str)
      return "<span style='color: #f87171;'>Invalid target. Use protocol number (1, 2, 3...).</span>" unless target_position

      result = Grid::BreachActionService.exec!(
        hackr: hackr,
        program_name: program_name,
        target_position: target_position
      )

      output = []
      if result.hit
        damage_color = result.protocol_destroyed ? "#34d399" : "#22d3ee"
        output << "<span style='color: #{damage_color};'>#{h(result.program_name)} → Protocol [#{result.target_position + 1}]: #{result.damage_dealt} damage#{" — DESTROYED" if result.protocol_destroyed}</span>"
        output << "<span style='color: #6b7280;'>Battery: -#{result.battery_consumed}</span>"
      else
        output << "<span style='color: #9ca3af;'>#{h(result.program_name)} → Protocol [#{result.target_position + 1}]: no effect.</span>"
      end

      # Achievement/mission hooks
      notifications = []
      if result.protocol_destroyed
        notifications += achievement_checker.check(:protocols_dismantled)
        notifications += mission_progressor.record(:dismantle_protocols, protocol_type: breach.grid_breach_protocols.find_by(position: target_position)&.protocol_type)
      end

      if result.all_destroyed
        # Resolve success
        resolve_result = Grid::BreachService.resolve_success!(hackr_breach: breach)
        output << resolve_result.display

        template = breach.grid_breach_template
        notifications += achievement_checker.check(:breach_completed, template_slug: template.slug, tier: template.tier)
        notifications += achievement_checker.check(:breaches_completed_count)
        notifications += mission_progressor.record(:complete_breach, template_slug: template.slug, tier: template.tier)

        if resolve_result.xp_result[:leveled_up]
          output << "<span style='color: #fbbf24; font-weight: bold;'>▲ CLEARANCE UP → #{resolve_result.xp_result[:new_clearance]}</span>"
        end
      else
        # Check if round should end
        breach.reload
        round_output = maybe_end_round
        output << round_output if round_output
      end

      append_notifications(output, notifications)
      output.join("\n")
    rescue Grid::BreachActionService::NoActionsRemaining,
      Grid::BreachActionService::ProgramNotLoaded,
      Grid::BreachActionService::InsufficientBattery,
      Grid::BreachActionService::InvalidTarget,
      Grid::BreachActionService::ProtocolAlreadyDestroyed => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    end

    def analyze_command(target_str)
      if target_str.nil?
        return "<span style='color: #fbbf24;'>Usage: analyze &lt;target#&gt;</span>"
      end

      target_position = parse_target(target_str)
      return "<span style='color: #f87171;'>Invalid target. Use protocol number (1, 2, 3...).</span>" unless target_position

      result = Grid::BreachActionService.analyze!(
        hackr: hackr,
        target_position: target_position
      )

      output = []
      output << "<span style='color: #22d3ee;'>ANALYZE → Protocol [#{result.target_position + 1}]: #{h(result.info_revealed)}</span>"
      output << "<span style='color: #34d399;'>  ▸ Bonus action!</span>" if result.bonus_action

      # Check if round should end
      breach.reload
      round_output = maybe_end_round
      output << round_output if round_output

      output.join("\n")
    rescue Grid::BreachActionService::NoActionsRemaining,
      Grid::BreachActionService::InvalidTarget,
      Grid::BreachActionService::ProtocolAlreadyDestroyed => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    end

    def reroute_command(target_str)
      if target_str.nil?
        return "<span style='color: #fbbf24;'>Usage: reroute &lt;target#&gt;</span>"
      end

      target_position = parse_target(target_str)
      return "<span style='color: #f87171;'>Invalid target. Use protocol number (1, 2, 3...).</span>" unless target_position

      result = Grid::BreachActionService.reroute!(
        hackr: hackr,
        target_position: target_position
      )

      output = []
      output << "<span style='color: #22d3ee;'>REROUTE → Protocol [#{result.target_position + 1}] (#{result.protocol_type_label}) delayed.</span>"

      # Check if round should end
      breach.reload
      round_output = maybe_end_round
      output << round_output if round_output

      output.join("\n")
    rescue Grid::BreachActionService::NoActionsRemaining,
      Grid::BreachActionService::InvalidTarget,
      Grid::BreachActionService::ProtocolAlreadyDestroyed,
      Grid::BreachActionService::AlreadyRerouted => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    end

    def jackout_command
      result = Grid::BreachService.jackout!(hackr: hackr)

      output = []
      output << result.display

      output << if result.clean
        "<span style='color: #34d399;'>You disconnect cleanly.</span>"
      else
        "<span style='color: #f87171;'>Emergency disconnect. System traced your exit.</span>"
      end

      output.join("\n")
    rescue Grid::BreachService::NotInBreach => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    end

    def status_command
      breach.reload
      Grid::BreachRenderer.new(breach).render_full
    end

    def deck_command
      deck = hackr.equipped_deck
      return "<span style='color: #f87171;'>No DECK equipped.</span>" unless deck

      output = []
      output << "<span style='color: #22d3ee; font-weight: bold;'>DECK :: #{h(deck.name)}</span>"
      output << "<span style='color: #fbbf24;'>Battery:</span> <span style='color: #d0d0d0;'>#{deck.deck_battery}/#{deck.deck_battery_max}</span>"
      output << "<span style='color: #fbbf24;'>Slots:</span> <span style='color: #d0d0d0;'>#{deck.deck_slots_used}/#{deck.deck_slot_count}</span>"
      output << ""

      loaded = deck.loaded_software.order(:name)
      if loaded.any?
        output << "<span style='color: #fbbf24;'>Loaded Software:</span>"
        loaded.each do |sw|
          cat = sw.properties&.dig("software_category") || "unknown"
          cost = sw.properties&.dig("battery_cost") || 0
          mag = sw.properties&.dig("effect_magnitude") || 0
          output << "  <span style='color: #d0d0d0;'>#{h(sw.name)}</span> <span style='color: #6b7280;'>[#{cat}]</span> <span style='color: #9ca3af;'>PWR:#{cost} DMG:#{mag}</span>"
        end
      else
        output << "<span style='color: #6b7280;'>No software loaded.</span>"
      end

      output.join("\n")
    end

    def help_command
      output = []
      output << "<span style='color: #22d3ee; font-weight: bold;'>══ BREACH COMMANDS ══</span>"
      output << ""
      output << "<span style='color: #fbbf24;'>exec &lt;program&gt; &lt;target#&gt;</span>  <span style='color: #9ca3af;'>Run software against a protocol (1 action + battery)</span>"
      output << "<span style='color: #fbbf24;'>analyze &lt;target#&gt;</span>           <span style='color: #9ca3af;'>Scan a protocol for intel (1 action)</span>"
      output << "<span style='color: #fbbf24;'>reroute &lt;target#&gt;</span>           <span style='color: #9ca3af;'>Delay a protocol 1 round (1 action, 30% chance protocol fizzles on retry)</span>"
      output << "<span style='color: #fbbf24;'>jackout</span>                      <span style='color: #9ca3af;'>Abort the encounter</span>"
      output << ""
      output << "<span style='color: #6b7280;'>Free commands (no action cost):</span>"
      output << "<span style='color: #fbbf24;'>status</span>                       <span style='color: #9ca3af;'>Show encounter state</span>"
      output << "<span style='color: #fbbf24;'>deck</span>                         <span style='color: #9ca3af;'>Show loaded software + battery</span>"
      output << "<span style='color: #fbbf24;'>help</span>                         <span style='color: #9ca3af;'>This reference</span>"
      output << ""
      output << "<span style='color: #6b7280;'>Aliases: sh=exec, an=analyze, rr=reroute, jo=jackout, st=status, dk=deck, ?=help</span>"
      output.join("\n")
    end

    def blocked_command(command)
      "<span style='color: #f87171;'>Cannot use '#{h(command)}' during BREACH. Type <span style='color: #22d3ee;'>help</span> for available commands.</span>"
    end

    def maybe_end_round
      breach.reload
      return nil if breach.actions_remaining > 0
      return nil unless breach.active?

      result = Grid::BreachService.end_round!(hackr_breach: breach)

      if result.state == :failure
        # Failure display already included in result.display
      end

      result.display
    end

    def parse_target(str)
      return nil unless str.to_s.match?(/\A\d+\z/)
      num = str.to_i
      return nil if num < 1
      num - 1 # Convert 1-indexed user input to 0-indexed position
    end

    def achievement_checker
      @achievement_checker ||= Grid::AchievementChecker.new(hackr)
    end

    def mission_progressor
      @mission_progressor ||= Grid::MissionProgressor.new(hackr)
    end

    def append_notifications(output, notifications)
      notifications.each { |n| output << n } if notifications&.any?
    end

    def h(text)
      ERB::Util.html_escape(text.to_s)
    end
  end
end
