# frozen_string_literal: true

module Grid
  class CodeService
    CODES = {
      "complete-tutorial" => :handle_complete_tutorial,
      "skip-tutorial" => :handle_complete_tutorial,
      "start-tutorial" => :handle_start_tutorial
    }.freeze

    def initialize(hackr)
      @hackr = hackr
    end

    def execute(code_string)
      code = code_string.to_s.strip.downcase
      return invalid_code if code.empty?

      handler = CODES[code]
      return invalid_code unless handler

      send(handler)
    end

    private

    def h(text)
      ERB::Util.html_escape(text.to_s)
    end

    def tutorial_service
      @tutorial_service ||= TutorialService.new(@hackr)
    end

    def handle_complete_tutorial
      unless tutorial_service.active?
        return "<span style='color: #9ca3af;'>Nothing happens.</span>"
      end

      # Re-entry: return to where they came from, no starting room selection
      if @hackr.stat("tutorial_return_room_id").present?
        tutorial_service.return_to_world!
        look_output = Grid::CommandParser.new(@hackr, "look").execute[:output]
        return "<span style='color: #34d399; font-weight: bold;'>[ BOOTLOADER TERMINATED ]</span>\n" \
          "<span style='color: #9ca3af;'>Returning to previous location...</span>\n\n" + look_output
      end

      # First-time: show starting room selection
      starting_rooms = GridStartingRoom.ordered.includes(:grid_room)
      if starting_rooms.empty?
        tutorial_service.complete!(starting_room: @hackr.current_room)
        return "<span style='color: #34d399; font-weight: bold;'>Tutorial skipped.</span>"
      end

      output = []
      output << "<span style='color: #22d3ee; font-weight: bold;'>[ TUTORIAL COMPLETE — CHOOSE STARTING LOCATION ]</span>"
      output << ""
      starting_rooms.each_with_index do |sr, i|
        output << "<span style='color: #fbbf24;'>[#{i + 1}]</span> <span style='color: #22d3ee; font-weight: bold;'>#{h(sr.name)}</span>"
        output << "    <span style='color: #d0d0d0;'>#{h(sr.blurb)}</span>"
        output << ""
      end
      output << "<span style='color: #9ca3af;'>Type</span> <span style='color: #22d3ee;'>choose &lt;number&gt;</span> <span style='color: #9ca3af;'>to select your starting location.</span>"

      @hackr.set_stat!("tutorial_choosing_start", true)
      output.join("\n")
    end

    def handle_start_tutorial
      if tutorial_service.active?
        return "<span style='color: #fbbf24;'>You are already in the tutorial.</span>"
      end

      tutorial_service.re_enter!
      look_output = Grid::CommandParser.new(@hackr, "look").execute[:output]
      "<span style='color: #34d399; font-weight: bold;'>[ BOOTLOADER REACTIVATED ]</span>\n" \
        "<span style='color: #9ca3af;'>Returning to training simulation...</span>\n\n" + look_output
    rescue TutorialService::CannotEnterTutorial => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    end

    def invalid_code
      "<span style='color: #9ca3af;'>Nothing happens.</span>"
    end
  end
end
