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
      [header_block, meters_block, protocols_block, circumvention_gates_block, footer_block].compact.join("\n")
    end

    def render_action_result(action_message)
      [action_message, "", render_compact_status].join("\n")
    end

    def render_compact_status
      [meters_block, protocols_block, circumvention_gates_block, footer_block].compact.join("\n")
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

    def render_success(xp_awarded, cred_awarded, template_name, fragments_granted = [])
      lines = []
      lines << ""
      lines << "<span style='color: #34d399; font-weight: bold;'>\u2554#{SEPARATOR}\u2557</span>"
      lines << "<span style='color: #34d399; font-weight: bold;'>\u2551  B R E A C H   C O M P L E T E                               \u2551</span>"
      lines << "<span style='color: #34d399; font-weight: bold;'>\u2560#{SEPARATOR}\u2563</span>"
      lines << "<span style='color: #34d399;'>\u2551</span>  <span style='color: #d0d0d0;'>#{h(template_name)}</span>"
      lines << "<span style='color: #34d399;'>\u2551</span>  <span style='color: #fbbf24;'>XP:</span> <span style='color: #34d399;'>+#{xp_awarded}</span>" if xp_awarded > 0
      lines << "<span style='color: #34d399;'>\u2551</span>  <span style='color: #fbbf24;'>CRED:</span> <span style='color: #34d399;'>+#{cred_awarded}</span>" if cred_awarded > 0
      if fragments_granted.any?
        lines << "<span style='color: #34d399;'>\u2551</span>  <span style='color: #a78bfa;'>FRAGMENTS:</span>"
        fragments_granted.each do |frag|
          qty_label = (frag[:quantity] > 1) ? " \u00d7#{frag[:quantity]}" : ""
          lines << "<span style='color: #34d399;'>\u2551</span>    <span style='color: #a78bfa;'>#{h(frag[:name])}#{qty_label}</span>"
        end
      end
      lines << "<span style='color: #34d399; font-weight: bold;'>\u255a#{SEPARATOR}\u255d</span>"
      lines.join("\n")
    end

    def render_failure(vitals_hit, zone_lockout_minutes = nil, fried_level: nil, software_wiped: false, failure_mode: :detection_overflow)
      border_red = "<span style='color: #f87171;'>\u2551</span>"
      lines = []
      lines << ""
      lines << "<span style='color: #f87171; font-weight: bold;'>\u2554#{SEPARATOR}\u2557</span>"
      lines << "<span style='color: #f87171; font-weight: bold;'>\u2551  B R E A C H   F A I L E D                                   \u2551</span>"
      lines << "<span style='color: #f87171; font-weight: bold;'>\u2560#{SEPARATOR}\u2563</span>"
      cause = if failure_mode == :health_zero
        "Neural link severed \u2014 vitals critical."
      else
        "Detection reached 100% \u2014 system countermeasures engaged."
      end
      lines << "#{border_red}  <span style='color: #d0d0d0;'>#{cause}</span>"
      vitals_hit.each do |hit|
        lines << "#{border_red}  <span style='color: #f87171;'>#{hit[:vital].upcase} -#{hit[:amount]}</span>"
      end
      if zone_lockout_minutes
        lines << "#{border_red}  <span style='color: #ef4444;'>Zone lockout: #{zone_lockout_minutes} minute(s)</span>"
      end
      if fried_level
        lines << border_red
        lines << "#{border_red}  <span style='color: #ef4444; font-weight: bold;'>\u26a0 DECK FRIED \u2014 neural feedback cascade (level #{fried_level}/5)</span>"
        lines << "#{border_red}  <span style='color: #f87171;'>All loaded software destroyed.</span>"
        lines << "#{border_red}  <span style='color: #9ca3af;'>Repair at a service node or craft a DECK Repair Kit (Mk.#{fried_level}+).</span>"
      elsif software_wiped
        lines << border_red
        lines << "#{border_red}  <span style='color: #ef4444; font-weight: bold;'>\u26a0 DECK OVERLOADED \u2014 all loaded software wiped.</span>"
        lines << "#{border_red}  <span style='color: #9ca3af;'>Reload software from inventory before your next BREACH.</span>"
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

    def render_sandbox_end(end_state, failure_mode: nil)
      color = (end_state == "success") ? "#34d399" : "#f87171"
      label = case end_state
      when "success" then "S A N D B O X   C O M P L E T E"
      when "failure" then "S A N D B O X   F A I L E D"
      when "jacked_out" then "S A N D B O X   J A C K - O U T"
      end
      cause = case end_state
      when "success" then "All protocols neutralized."
      when "failure"
        (failure_mode == :health_zero) ? "Neural link severed \u2014 vitals critical." : "Detection reached 100%."
      when "jacked_out" then "Disconnected from encounter."
      end

      lines = []
      lines << ""
      lines << "<span style='color: #{color}; font-weight: bold;'>\u2554#{SEPARATOR}\u2557</span>"
      lines << "<span style='color: #{color}; font-weight: bold;'>\u2551  #{label}#{" " * [62 - label.length - 4, 0].max}\u2551</span>"
      lines << "<span style='color: #{color}; font-weight: bold;'>\u2560#{SEPARATOR}\u2563</span>"
      lines << "<span style='color: #{color};'>\u2551</span>  <span style='color: #d0d0d0;'>#{cause}</span>"
      lines << "<span style='color: #{color};'>\u2551</span>"
      lines << "<span style='color: #{color};'>\u2551</span>  <span style='color: #fbbf24;'>SANDBOX MODE \u2014 no consequences applied.</span>"
      lines << "<span style='color: #{color};'>\u2551</span>  <span style='color: #9ca3af;'>Vitals and DECK battery restored to pre-breach state.</span>"
      lines << "<span style='color: #{color}; font-weight: bold;'>\u255a#{SEPARATOR}\u255d</span>"
      lines.join("\n")
    end

    private

    def header_block
      template = @breach.grid_breach_template
      tier_label = template.tier_label
      alive_count = @protocols.count(&:alive?)
      sandbox_tag = @breach.sandbox? ? "  <span style='color: #fbbf24; font-weight: bold;'>[SANDBOX]</span>" : ""
      [
        "<span style='color: #{BORDER_COLOR};'>\u2554#{SEPARATOR}\u2557</span>",
        "<span style='color: #{BORDER_COLOR};'>\u2551</span>  <span style='color: #22d3ee; font-weight: bold;'>B R E A C H</span>  <span style='color: #6b7280;'>::</span>  <span style='color: #d0d0d0;'>#{h(template.name)}</span>#{sandbox_tag}",
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
          lines << "#{border}  <span style='color: #6b7280;'>[#{p.position + 1}] \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500 \u2713 CLEARED</span>"
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

        lines << "#{border}  <span style='color: #9ca3af;'>[#{p.position + 1}]</span> #{health_bar}  #{type_hint}  <span style='color: #9ca3af;'>#{state_label}#{state_info}</span>  <span style='color: #6b7280;'>weak:</span> #{weakness_hint}"
      end
      lines << "<span style='color: #{BORDER_COLOR};'>\u2560#{SEPARATOR}\u2563</span>"
      lines.join("\n")
    end

    def circumvention_gates_block
      ps = @breach.meta&.dig("puzzle_state")
      return nil unless ps&.dig("gates")&.any?

      lines = ["#{border}  <span style='color: #fbbf24; font-weight: bold;'>PROTOCOL CIRCUMVENTION GATES</span>"]
      ps["gates"].each do |gate_id, gate|
        state = gate["state"]
        type_label = gate["type"].to_s.tr("_", " ").split.map(&:capitalize).join(" ")

        state_color, icon, status_text = case state
        when "solved"
          ["#34d399", "\u2713", "COMPLETE"]
        when "bypassed"
          ["#34d399", "\u2713", "BYPASSED"]
        when "failed"
          ["#f87171", "\u2717", "FAILED"]
        when "locked"
          ["#6b7280", "\u25a1", "locked (solve #{gate["depends_on"]} first)"]
        else # active
          attempts_text = if gate["max_attempts"].to_i == Grid::BreachService::UNLIMITED_ATTEMPTS
            "unlimited attempts"
          else
            "#{gate["attempts_remaining"]}/#{gate["max_attempts"]} attempts"
          end
          ["#d0d0d0", "\u25cb", attempts_text]
        end

        lines << "#{border}  <span style='color: #9ca3af;'>[#{gate_id}]</span> <span style='color: #d0d0d0;'>#{h(type_label)}</span>  <span style='color: #{state_color};'>#{icon} #{h(status_text)}</span>"

        # Render puzzle display data for active gates (locked gates just show status)
        if state == "active" && gate["display"]
          lines.concat(render_gate_display(gate_id, gate))
        end
      end
      lines << "<span style='color: #{BORDER_COLOR};'>\u2560#{SEPARATOR}\u2563</span>"
      lines.join("\n")
    end

    def footer_block
      rank_data = Grid::BreachService.breach_rank(@hackr.stat("clearance"))
      rank_label = rank_data ? rank_data[:rank] : "Unknown"
      [
        "#{border}  <span style='color: #9ca3af;'>Round #{@breach.round_number}</span>  <span style='color: #6b7280;'>\u2014</span>  <span style='color: #9ca3af;'>#{@breach.actions_remaining} actions remaining</span>",
        "#{border}  <span style='color: #fbbf24;'>YOUR BREACH RANK:</span> <span style='color: #22d3ee;'>#{h(rank_label)}</span>",
        "<span style='color: #{BORDER_COLOR};'>\u255a#{SEPARATOR}\u255d</span>"
      ].join("\n")
    end

    def render_gate_display(gate_id, gate)
      d = gate["display"]
      return [] unless d
      lines = []
      lines << "#{border}    <span style='color: #6b7280;'>#{h(d["prompt"])}</span>" if d["prompt"]

      case d["type"]
      when "credential"
        ciphers = d["ciphers"] || [d["encrypted"]].compact
        if ciphers.size == 1
          lines << "#{border}    <span style='color: #fbbf24;'>Encrypted:</span> <span style='color: #e0e0e0; font-weight: bold;'>#{h(ciphers[0])}</span>"
        else
          ciphers.each_with_index do |c, i|
            lines << "#{border}    <span style='color: #fbbf24;'>Cipher #{i + 1}:</span>  <span style='color: #e0e0e0; font-weight: bold;'>#{h(c)}</span>"
          end
        end
        hints = d["substitution_hints"] || (d["cipher_hint"].present? ? [d["cipher_hint"]] : [])
        if hints.any?
          lines << "#{border}    <span style='color: #fbbf24;'>Known substitutions:</span> #{hints.map { |s| "<span style='color: #34d399;'>#{h(s)}</span>" }.join("  ")}"
        end
      when "sequence"
        nodes = d["nodes"]
        lines << "#{border}    <span style='color: #fbbf24;'>Nodes:</span> #{nodes.map { |n| "<span style='color: #e0e0e0;'>#{h(n)}</span>" }.join("  ")}" if nodes
      when "logic_gate"
        lines << "#{border}    <span style='color: #e0e0e0;'>#{h(d["diagram"])}</span>" if d["diagram"]
      when "circuit"
        left = d["left_nodes"]
        right = d["right_nodes"]
        if left && right
          lines << "#{border}    <span style='color: #fbbf24;'>Left:</span>  #{left.map { |n| "<span style='color: #e0e0e0;'>#{h(n)}</span>" }.join("  ")}"
          lines << "#{border}    <span style='color: #fbbf24;'>Right:</span> #{right.map { |n| "<span style='color: #e0e0e0;'>#{h(n)}</span>" }.join("  ")}"
        end
        probes_remaining = gate["probes_remaining"].to_i
        probe_results = gate["probe_results"] || {}
        lines << "#{border}    <span style='color: #fbbf24;'>Probes:</span> <span style='color: #d0d0d0;'>#{probes_remaining} remaining</span>"
        probe_results.each do |pair, connected|
          color = connected ? "#34d399" : "#f87171"
          icon = connected ? "\u2713 CONNECTED" : "\u2717 NO SIGNAL"
          lines << "#{border}      <span style='color: #{color};'>#{icon}: #{h(pair)}</span>"
        end
      end

      # Type-specific usage hints
      if d["type"] == "circuit"
        lines << "#{border}    <span style='color: #6b7280;'>Probe: interface #{gate_id} probe NODE1-NODE2</span>"
        lines << "#{border}    <span style='color: #6b7280;'>Solve: interface #{gate_id} NODE1-NODE2 NODE3-NODE4 ...</span>"
      else
        lines << "#{border}    <span style='color: #6b7280;'>Use: interface #{gate_id} &lt;answer&gt;</span>"
      end
      lines
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
