# frozen_string_literal: true

module Grid
  class TransitCommandParser
    # Commands delegated to main parser while in transit
    PASSTHROUGH_COMMANDS = %w[
      look l stat stats st inventory inv i help ? who clear cls cl
      say examine ex x code
    ].freeze

    attr_reader :hackr, :input, :journey, :parser

    def initialize(hackr, input, journey, parser)
      @hackr = hackr
      @input = input.to_s.strip
      @journey = journey
      @parser = parser
    end

    def execute
      return {output: "<span style='color: #fbbf24;'>Please enter a command.</span>", event: nil} if input.empty?

      # Handle breach-just-resumed for slipstream
      if journey.slipstream? && journey.breach_mid_journey? && !hackr.in_breach?
        resume_result = Grid::SlipstreamService.handle_breach_resume!(hackr: hackr)
        @journey = hackr.active_journey

        unless resume_result.continued
          # Ejected — show ejection + look at new room
          output = resume_result.display + "\n" + parser.send(:look_command)
          return {output: output, event: nil}
        end

        # Journey continues — show resume message, then fall through to process current command
        # If journey ended (completed/ejected), no active journey anymore
        unless @journey&.active?
          return {output: resume_result.display + "\n" + parser.send(:look_command), event: nil}
        end

        # Prepend resume display to whatever command result follows
        @resume_prefix = resume_result.display + "\n"
      end

      parts = input.split
      command = parts.first&.downcase
      args = parts[1..]

      result = dispatch_transit_command(command, args)
      result = result.is_a?(Hash) ? result : {output: result, event: nil}

      # Prepend resume message if applicable
      if @resume_prefix
        result[:output] = @resume_prefix + result[:output].to_s
      end

      result
    end

    private

    def dispatch_transit_command(command, args)
      case command
      # Universal transit commands
      when "wait", "w", "w8", "ride"
        wait_command
      when "disembark", "off"
        disembark_command
      when "abandon", "abort"
        abandon_command
      when "transit", "tr", "ts", "status"
        transit_status_command

      # Slipstream-specific
      when "choose", "ch"
        choose_command(args&.first)
      when "advance", "adv"
        advance_command

      # Passthrough to main parser
      when *PASSTHROUGH_COMMANDS
        parser.send(:dispatch_command, command, args)

      else
        transit_blocked_message(command)
      end
    end

    def wait_command
      if journey.slipstream?
        # For slipstream, 'wait' is an alias for 'advance'
        return advance_command
      end

      result = Grid::LocalTransitService.wait!(hackr: hackr)
      output = result.display

      if result.arrived
        notifications = fire_transit_hooks
        output = append_notifications(output, notifications)
        output += "\n" + parser.send(:look_command)
      end

      {output: output, event: nil}
    rescue Grid::LocalTransitService::NotInJourney
      "<span style='color: #f87171;'>Not currently in transit.</span>"
    end

    def disembark_command
      unless journey.local?
        return "<span style='color: #f87171;'>Cannot disembark from Slipstream. Use <span style='color: #a78bfa;'>abandon</span> to abort.</span>"
      end

      result = Grid::LocalTransitService.disembark!(hackr: hackr)
      notifications = fire_transit_hooks
      output = result.display
      output = append_notifications(output, notifications)
      output += "\n" + parser.send(:look_command)
      {output: output, event: nil}
    rescue Grid::LocalTransitService::NotInJourney
      "<span style='color: #f87171;'>Not currently in transit.</span>"
    end

    def abandon_command
      result = if journey.slipstream?
        Grid::SlipstreamService.abandon!(hackr: hackr)
      else
        Grid::LocalTransitService.abandon!(hackr: hackr)
      end
      output = result.display + "\n" + parser.send(:look_command)
      {output: output, event: nil}
    rescue Grid::SlipstreamService::NotInJourney, Grid::LocalTransitService::NotInJourney
      "<span style='color: #f87171;'>Not currently in transit.</span>"
    end

    def transit_status_command
      result = if journey.slipstream?
        Grid::SlipstreamService.status(hackr: hackr)
      else
        Grid::LocalTransitService.status(hackr: hackr)
      end
      {output: result.display, event: nil}
    rescue Grid::SlipstreamService::NotInJourney, Grid::LocalTransitService::NotInJourney
      "<span style='color: #f87171;'>Not currently in transit.</span>"
    end

    def choose_command(fork_key)
      unless journey.slipstream?
        return "<span style='color: #9ca3af;'>Fork choices are only available on Slipstream routes.</span>"
      end
      unless fork_key
        return "<span style='color: #fbbf24;'>Specify a fork: choose &lt;key&gt;</span>"
      end

      result = Grid::SlipstreamService.choose_fork!(hackr: hackr, fork_key: fork_key)
      {output: result.display, event: nil}
    rescue Grid::SlipstreamService::NotAwaitingFork
      "<span style='color: #9ca3af;'>No fork choice pending at this leg.</span>"
    rescue Grid::SlipstreamService::InvalidForkKey
      "<span style='color: #f87171;'>Unknown fork: '#{h(fork_key)}'. Type <span style='color: #a78bfa;'>status</span> to see options.</span>"
    end

    def advance_command
      unless journey.slipstream?
        return "<span style='color: #9ca3af;'>Advance is for Slipstream transit. Use <span style='color: #22d3ee;'>wait</span> for local transit.</span>"
      end

      if journey.awaiting_fork?
        leg = journey.current_leg
        return Grid::TransitRenderer.render_leg_prompt(leg, journey.legs_completed + 1, journey.total_legs)
      end

      result = Grid::SlipstreamService.advance_leg!(hackr: hackr)

      if result.completed
        notifications = fire_slipstream_hooks
        output = append_notifications(result.display, notifications)
        output += "\n" + parser.send(:look_command)
        return {output: output, event: nil}
      end

      {output: result.display, event: nil}
    rescue Grid::SlipstreamService::NotInJourney
      "<span style='color: #f87171;'>Not in Slipstream transit.</span>"
    end

    def fire_transit_hooks
      notifications = []
      type_slug = journey.grid_transit_route&.grid_transit_type&.slug
      notifications += achievement_checker.check(:local_transit_completed, transit_type_slug: type_slug)
      notifications += achievement_checker.check(:transits_completed_count)
      notifications += mission_progressor.record(:complete_transit, transit_type_slug: type_slug)
      notifications
    end

    def fire_slipstream_hooks
      notifications = []
      route_slug = journey.grid_slipstream_route&.slug
      region_slug = journey.grid_slipstream_route&.destination_region&.slug
      notifications += achievement_checker.check(:slipstream_completed, route_slug: route_slug)
      notifications += achievement_checker.check(:slipstreams_completed_count)
      notifications += achievement_checker.check(:regions_visited_count)
      notifications += mission_progressor.record(:complete_slipstream, route_slug: route_slug)
      notifications += mission_progressor.record(:reach_region, region_slug: region_slug)
      notifications
    end

    def transit_blocked_message(command)
      "<span style='color: #f87171;'>In transit — '#{h(command)}' unavailable. Type <span style='color: #22d3ee;'>help</span> for transit commands.</span>"
    end

    def append_notifications(output, notifications)
      return output if notifications.empty?
      output + "\n" + notifications.join("\n")
    end

    def h(text) = ERB::Util.html_escape(text.to_s)
    def achievement_checker = @achievement_checker ||= Grid::AchievementChecker.new(hackr)
    def mission_progressor = @mission_progressor ||= Grid::MissionProgressor.new(hackr)
  end
end
