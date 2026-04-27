# frozen_string_literal: true

module Grid
  # Subclass of CommandParser for the admin NPC Dialogue Tester.
  # Inherits all routing and rendering from CommandParser while suppressing
  # side effects via two layers:
  #
  # 1. Override side-effect helpers to no-op (increment_stat!, grant_faction_rep)
  #    and replace achievement/mission services with null objects.
  # 2. Wrap write-heavy commands (buy, sell, give, accept, turn_in) in an
  #    always-rollback transaction — output is captured before revert.
  #
  # Read-only commands (talk, ask, examine, shop, look, etc.) pass through
  # the inherited implementation unchanged — the null-object overrides
  # silently discard their notification payloads.
  class NpcDialogueCommandParser < CommandParser
    TESTER_BANNER = "[TESTER]"

    # Read-only commands that pass through with null-object side-effect suppression
    READ_COMMANDS = %w[
      look l examine ex x talk ask shop browse
      missions quests mission quest
      stat stats st rep reputation standing
      inventory inv i loadout lo deck dk
      who help ? clear cls cl
    ].freeze

    # Write commands wrapped in always-rollback transaction
    WRITE_COMMANDS = %w[
      buy purchase sell
      accept acc ac turn_in turnin ti
      abandon
      give
    ].freeze

    ALLOWED_COMMANDS = (READ_COMMANDS + WRITE_COMMANDS).freeze

    # Override execute to bypass breach/captured routing.
    # The tester operates in normal command mode regardless of hackr state.
    def execute
      return {output: "<span style='color: #fbbf24;'>Please enter a command.</span>", event: nil} if input.empty?

      parts = input.split
      command = parts.first&.downcase
      args = parts[1..]

      result = dispatch_command(command, args)
      result.is_a?(Hash) ? result : {output: result, event: nil}
    end

    def dispatch_command(command, args)
      unless ALLOWED_COMMANDS.include?(command)
        return "<span style='color: #f87171;'>#{TESTER_BANNER} Command not available in NPC Dialogue Tester.</span>\n" \
               "<span style='color: #9ca3af;'>Available: talk, ask, examine, shop, buy, sell, give, accept, turn_in, " \
               "missions, mission, stat, rep, inventory, loadout, deck, look, who, help</span>"
      end

      if WRITE_COMMANDS.include?(command)
        # Wrap write commands in an always-rollback transaction.
        # Output string is captured before the rollback executes.
        raw = nil
        ActiveRecord::Base.transaction do
          raw = super
          raise ActiveRecord::Rollback
        end
        output = raw.is_a?(Hash) ? raw[:output] : raw
        rollback_notice = "<span style='color: #fbbf24;'>#{TESTER_BANNER} Write reverted — no persistent changes.</span>"
        "#{output}\n#{rollback_notice}"
      else
        super
      end
    end

    # --- Side-effect suppressors ---

    def increment_stat!(_key, _amount = 1)
      nil
    end

    def grant_faction_rep(_faction, _delta, reason: nil, source: nil)
      nil
    end

    def achievement_checker
      @achievement_checker ||= Grid::NpcDialogue::NullAchievementChecker.new
    end

    def mission_progressor
      @mission_progressor ||= Grid::NpcDialogue::NullMissionProgressor.new
    end
  end
end
