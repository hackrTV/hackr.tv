# frozen_string_literal: true

module Grid
  # Renders all BREACH encounter display chrome.
  # Stateless — reads from the breach and protocol objects passed to it.
  class BreachRenderer
    BORDER_COLOR = "#22d3ee"
    DETECT_COLOR = "#f87171"
    BATTERY_COLOR = "#fbbf24"
    INSPIRE_COLOR = "#a78bfa"

    PROTOCOL_COLORS = {
      "trace" => "#f59e0b",
      "feedback" => "#f87171",
      "lock" => "#ef4444",
      "adapt" => "#a78bfa",
      "spike" => "#dc2626",
      "purge" => "#8b5cf6"
    }.freeze

    STATE_LABELS = {
      "idle" => "idle",
      "charging" => "charging",
      "active" => "ACTIVE",
      "destroyed" => "\u2713 CLEARED"
    }.freeze

    SEPARATOR = "\u2550" * 62 # ═ repeated

    def initialize(breach, protocols = nil)
      @breach = breach
      @protocols = protocols || breach.grid_breach_protocols.ordered.to_a
      @hackr = breach.grid_hackr
      @deck = @hackr.equipped_deck
    end

    def render_full
      [header_block, meters_block, protocols_block, footer_block].join("\n")
    end

    def render_action_result(action_message)
      [action_message, "", render_compact_status].join("\n")
    end

    def render_compact_status
      [meters_block, protocols_block, footer_block].join("\n")
    end

    def render_round_end(protocol_messages)
      lines = ["<span style='color: #9ca3af;'>\u2500\u2500 SYSTEM TURN \u2500\u2500</span>"]
      if protocol_messages.any?
        lines.concat(protocol_messages)
      else
        lines << "<span style='color: #6b7280;'>Protocols cycling...</span>"
      end
      lines << ""
      lines << render_full
      lines.join("\n")
    end

    def render_success(xp_awarded, cred_awarded, template_name)
      lines = []
      lines << ""
      lines << "<span style='color: #34d399; font-weight: bold;'>\u2554#{SEPARATOR}\u2557</span>"
      lines << "<span style='color: #34d399; font-weight: bold;'>\u2551  B R E A C H   C O M P L E T E                              \u2551</span>"
      lines << "<span style='color: #34d399; font-weight: bold;'>\u2560#{SEPARATOR}\u2563</span>"
      lines << "<span style='color: #34d399;'>\u2551</span>  <span style='color: #d0d0d0;'>#{h(template_name)}</span>"
      lines << "<span style='color: #34d399;'>\u2551</span>  <span style='color: #fbbf24;'>XP:</span> <span style='color: #34d399;'>+#{xp_awarded}</span>" if xp_awarded > 0
      lines << "<span style='color: #34d399;'>\u2551</span>  <span style='color: #fbbf24;'>CRED:</span> <span style='color: #34d399;'>+#{cred_awarded}</span>" if cred_awarded > 0
      lines << "<span style='color: #34d399; font-weight: bold;'>\u255a#{SEPARATOR}\u255d</span>"
      lines.join("\n")
    end

    def render_failure(vitals_hit, zone_lockout_minutes = nil)
      lines = []
      lines << ""
      lines << "<span style='color: #f87171; font-weight: bold;'>\u2554#{SEPARATOR}\u2557</span>"
      lines << "<span style='color: #f87171; font-weight: bold;'>\u2551  B R E A C H   F A I L E D                                   \u2551</span>"
      lines << "<span style='color: #f87171; font-weight: bold;'>\u2560#{SEPARATOR}\u2563</span>"
      lines << "<span style='color: #f87171;'>\u2551</span>  <span style='color: #d0d0d0;'>Detection reached 100% \u2014 system countermeasures engaged.</span>"
      vitals_hit.each do |hit|
        lines << "<span style='color: #f87171;'>\u2551</span>  <span style='color: #f87171;'>#{hit[:vital].upcase} -#{hit[:amount]}</span>"
      end
      if zone_lockout_minutes
        lines << "<span style='color: #f87171;'>\u2551</span>  <span style='color: #ef4444;'>Zone lockout: #{zone_lockout_minutes} minute(s)</span>"
      end
      lines << "<span style='color: #f87171; font-weight: bold;'>\u255a#{SEPARATOR}\u255d</span>"
      lines.join("\n")
    end

    def render_jackout(clean, vitals_hit)
      color = clean ? "#34d399" : "#f87171"
      label = clean ? "JACK-OUT CLEAN" : "JACK-OUT COMPROMISED"
      lines = []
      lines << ""
      lines << "<span style='color: #{color}; font-weight: bold;'>[ #{label} ]</span>"
      vitals_hit.each do |hit|
        lines << "<span style='color: #9ca3af;'>  #{hit[:vital].upcase} -#{hit[:amount]}</span>"
      end
      lines.join("\n")
    end

    def render_pnr_warning
      "<span style='color: #f87171; font-weight: bold;'>\u26a0 SYSTEM ALERT: Intrusion signature locked. Jack-out route compromised.</span>"
    end

    private

    def header_block
      template = @breach.grid_breach_template
      tier_label = template.tier_label
      alive_count = @protocols.count(&:alive?)
      [
        "<span style='color: #{BORDER_COLOR};'>\u2554#{SEPARATOR}\u2557</span>",
        "<span style='color: #{BORDER_COLOR};'>\u2551</span>  <span style='color: #22d3ee; font-weight: bold;'>B R E A C H</span>  <span style='color: #6b7280;'>::</span>  <span style='color: #d0d0d0;'>#{h(template.name)}</span>",
        "<span style='color: #{BORDER_COLOR};'>\u2551</span>  <span style='color: #fbbf24;'>Tier:</span> <span style='color: #d0d0d0;'>#{tier_label}</span>    <span style='color: #fbbf24;'>Protocols:</span> <span style='color: #f87171;'>#{alive_count} active</span>",
        "<span style='color: #{BORDER_COLOR};'>\u2560#{SEPARATOR}\u2563</span>"
      ].join("\n")
    end

    def meters_block
      detect = @breach.detection_level
      pnr = @breach.pnr_threshold
      battery = @deck&.deck_battery || 0
      battery_max = @deck&.deck_battery_max || 0
      actions = @breach.actions_remaining
      actions_total = @breach.actions_this_round
      reward_mult = @breach.reward_multiplier
      pnr_crossed = detect >= pnr

      pnr_label = pnr_crossed ?
        " <span style='color: #f87171; font-weight: bold;'>[PNR CROSSED]</span>" : ""

      lines = [
        "#{border}  <span style='color: #fbbf24;'>DETECTION</span>  #{bar(detect, 100, DETECT_COLOR)}  #{detect}%#{pnr_label}",
        "#{border}              <span style='color: #6b7280;'>PNR \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u25b6</span>  #{pnr}%",
        "#{border}  <span style='color: #fbbf24;'>BATTERY  </span>  #{bar(battery, battery_max, BATTERY_COLOR)}  #{battery}/#{battery_max}",
        "#{border}  <span style='color: #fbbf24;'>ACTIONS  </span>  #{bar(actions, actions_total, INSPIRE_COLOR)}  #{actions}/#{actions_total}"
      ]

      # Show reward multiplier when degraded by PURGE
      if reward_mult < 1.0
        pct = (reward_mult * 100).round
        reward_color = (pct >= 70) ? "#34d399" : "#8b5cf6"
        lines << "#{border}  <span style='color: #fbbf24;'>REWARDS  </span>  #{bar(pct, 100, reward_color)}  #{pct}%"
      end

      lines << "<span style='color: #{BORDER_COLOR};'>\u2560#{SEPARATOR}\u2563</span>"
      lines.join("\n")
    end

    def protocols_block
      lines = ["#{border}  <span style='color: #fbbf24; font-weight: bold;'>ACTIVE PROTOCOLS</span>"]
      @protocols.each do |p|
        color = PROTOCOL_COLORS[p.protocol_type] || "#9ca3af"
        state_label = STATE_LABELS[p.state] || p.state.upcase
        analyze = p.analyze_level

        if p.destroyed?
          lines << "  <span style='color: #6b7280;'>[#{p.position + 1}] \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 \u2713 CLEARED</span>"
          next
        end

        type_hint = if analyze >= 1
          "<span style='color: #{color};'>#{p.type_label}</span>"
        else
          "<span style='color: #6b7280;'>???</span>"
        end

        weakness_hint = if analyze >= 2 && p.weakness.present?
          "<span style='color: #34d399;'>#{p.weakness}</span>"
        elsif analyze >= 2
          "<span style='color: #6b7280;'>none</span>"
        else
          "<span style='color: #6b7280;'>?</span>"
        end

        health_bar = bar(p.health, p.max_health, color, width: 8)

        state_info = if p.state == "charging"
          remaining = p.charge_rounds - p.rounds_charging
          " <span style='color: #6b7280;'>(#{remaining} rounds)</span>"
        elsif p.rerouted?
          " <span style='color: #22d3ee;'>[REROUTED]</span>"
        elsif p.meta["fizzle_check"]
          " <span style='color: #22d3ee;'>[RETRYING]</span>"
        else
          ""
        end

        lines << "  <span style='color: #9ca3af;'>[#{p.position + 1}]</span> #{health_bar}  #{type_hint}  <span style='color: #9ca3af;'>#{state_label}#{state_info}</span>  <span style='color: #6b7280;'>weak:</span> #{weakness_hint}"
      end
      lines << "<span style='color: #{BORDER_COLOR};'>\u2560#{SEPARATOR}\u2563</span>"
      lines.join("\n")
    end

    def footer_block
      rank_data = Grid::BreachService.breach_rank(@hackr.stat("clearance"))
      rank_label = rank_data ? rank_data[:rank] : "Unknown"
      [
        "#{border}  <span style='color: #9ca3af;'>Round #{@breach.round_number}</span>  <span style='color: #6b7280;'>\u2014</span>  <span style='color: #9ca3af;'>#{@breach.actions_remaining} actions remaining</span>",
        "#{border}  <span style='color: #fbbf24;'>BREACH RANK:</span> <span style='color: #22d3ee;'>#{h(rank_label)}</span>",
        "<span style='color: #{BORDER_COLOR};'>\u255a#{SEPARATOR}\u255d</span>"
      ].join("\n")
    end

    def bar(current, max, color, width: 16)
      return "<span style='color: #6b7280;'>#{"░" * width}</span>" if max <= 0
      filled = [(current.to_f / max * width).round, width].min
      empty = width - filled
      "<span style='color: #{color};'>#{"█" * filled}#{"░" * empty}</span>"
    end

    def border
      "<span style='color: #{BORDER_COLOR};'>\u2551</span>"
    end

    def h(text)
      ERB::Util.html_escape(text.to_s)
    end
  end
end
