module Grid
  class CommandParser
    include CodexHelper

    attr_reader :hackr, :input, :event

    def initialize(hackr, input)
      @hackr = hackr
      @input = input.to_s.strip
      @event = nil
    end

    # Escape HTML to prevent XSS attacks from user input
    def h(text)
      ERB::Util.html_escape(text.to_s)
    end

    def execute
      return {output: "<span style='color: #fbbf24;'>Please enter a command.</span>", event: nil} if input.empty?

      # Split input but preserve case in arguments
      parts = input.split
      command = parts.first&.downcase
      args = parts[1..]

      result = case command
      when "look", "l"
        look_command
      when "go", "move"
        go_command(args.first)
      when "north", "n"
        go_command("north")
      when "south", "s"
        go_command("south")
      when "east", "e"
        go_command("east")
      when "west", "w"
        go_command("west")
      when "up", "u"
        go_command("up")
      when "down", "d"
        go_command("down")
      when "say"
        say_command(args.join(" "))
      when "inventory", "inv", "i"
        inventory_command
      when "take", "get"
        take_command(args.join(" "))
      when "drop"
        drop_command(args.join(" "))
      when "examine", "ex", "x"
        examine_command(args.join(" "))
      when "talk"
        talk_command(args.join(" "))
      when "ask"
        ask_command(args)
      when "stat", "stats"
        stat_command
      when "use"
        use_command(args.join(" "))
      when "salvage"
        salvage_command(args.join(" "))
      when "help", "?"
        help_command
      when "who"
        who_command
      when "clear", "cls"
        clear_command
      else
        "<span style='color: #f87171;'>Unknown command: #{h(command)}. Type 'help' for a list of commands.</span>"
      end

      # Normalize result to hash format
      result.is_a?(Hash) ? result : {output: result, event: nil}
    end

    private

    def look_command
      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere. This shouldn't happen!</span>" unless room

      output = []
      output << "\n<span style='color: #a78bfa;'>════════════════════════════════════════════════════════════════</span>"
      output << "<span style='color: #22d3ee; font-weight: bold;'>#{room.name.upcase}</span> <span style='color: #666;'>::</span> <span style='color: #fbbf24;'>#{room.grid_zone.name}</span>"
      output << "<span style='color: #9ca3af;'>[#{room.color_scheme}]</span>" if room.color_scheme
      output << ""
      output << "<span style='color: #d0d0d0;'>#{codex_linkify(room.description)}</span>" if room.description
      output << ""

      # Show exits
      exits = room.exits_from.includes(:to_room)
      if exits.any?
        exit_list = exits.map { |e| "<span style='color: #22d3ee;'>#{e.direction}</span> <span style='color: #9ca3af;'>(#{e.to_room.name})</span>" }.join(", ")
        output << "<span style='color: #fbbf24;'>Exits:</span> #{exit_list}"
      else
        output << "<span style='color: #fbbf24;'>Exits:</span> <span style='color: #6b7280;'>none</span>"
      end

      # Show items
      items = room.grid_items.in_room(room)
      if items.any?
        output << ""
        item_names = items.map { |item| item.unicorn? ? item.rainbow_name_html : "<span style='color: #34d399;'>#{h(item.name)}</span>" }
        output << "<span style='color: #fbbf24;'>Items:</span> #{item_names.join(", ")}"
      end

      # Show Mobs
      mobs = room.grid_mobs
      if mobs.any?
        output << ""
        output << "<span style='color: #fbbf24;'>Mobs:</span> <span style='color: #c084fc;'>#{mobs.map(&:name).join(", ")}</span>"
      end

      # Show other hackrs (only recently active ones)
      other_hackrs = room.grid_hackrs.recently_active.where.not(id: hackr.id)
      if other_hackrs.any?
        output << ""
        output << "<span style='color: #fbbf24;'>Hackrs:</span> <span style='color: #a78bfa;'>#{other_hackrs.map(&:hackr_alias).join(", ")}</span>"
      end

      output.join("\n")
    end

    def go_command(direction)
      return "<span style='color: #fbbf24;'>Go where? Specify a direction: north, south, east, west, up, down</span>" unless direction

      old_room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless old_room

      exit = old_room.exits_from.find_by(direction: direction)
      return "<span style='color: #f87171;'>You can't go #{direction} from here.</span>" unless exit

      if exit.locked
        return "<span style='color: #f87171;'>The exit is locked.</span>" unless exit.requires_item && hackr.grid_items.exists?(exit.requires_item_id)
      end

      new_room = exit.to_room
      hackr.update!(current_room: new_room)

      # Track exploration (unique rooms via visited_rooms array in stats)
      visited = hackr.stat("visited_rooms") || []
      if visited.include?(new_room.id)
        hackr.grant_xp!(1) # Small XP for movement
      else
        visited += [new_room.id]
        hackr.set_stat!("visited_rooms", visited)
        hackr.set_stat!("rooms_visited", visited.size)
        hackr.grant_xp!(5) # Bonus XP for new room discovery
      end

      look_output = look_command
      notifications = achievement_checker.check(:room_visit, room_slug: new_room.slug)
      notifications += achievement_checker.check(:rooms_visited)
      look_output = append_notifications(look_output, notifications)

      {
        output: look_output,
        event: {
          type: "movement",
          hackr_alias: hackr.hackr_alias,
          direction: direction,
          from_room_id: old_room.id,
          to_room_id: new_room.id
        }
      }
    end

    def say_command(message)
      if message.empty?
        return {
          output: "<span style='color: #fbbf24;'>Say what?</span>",
          event: nil
        }
      end

      grid_message = GridMessage.new(
        grid_hackr: hackr,
        room: hackr.current_room,
        message_type: "say",
        content: message
      )

      unless grid_message.save
        return {
          output: "<span style='color: #ef4444;'>#{grid_message.errors[:content].first || "Transmission failed."}</span>",
          event: nil
        }
      end

      # Don't return output - the broadcast handles displaying the message to everyone including sender
      {
        output: nil,
        event: {
          type: "say",
          hackr_alias: hackr.hackr_alias,
          message: message,
          room_id: hackr.current_room&.id
        }
      }
    end

    def inventory_command
      items = hackr.grid_items
      return "<span style='color: #9ca3af;'>Your inventory is empty.</span>" unless items.any?

      lines = ["<span style='color: #fbbf24;'>Inventory:</span>"]
      items.each do |item|
        color = item.rarity_color
        name_display = item.unicorn? ? item.rainbow_name_html : "<span style='color: #{color};'>#{h(item.name)}</span>"
        rarity_tag = item.rarity ? " <span style='color: #{color};'>[#{item.rarity_label}]</span>" : ""
        qty_tag = (item.quantity > 1) ? " <span style='color: #6b7280;'>x#{item.quantity}</span>" : ""
        lines << "  - #{name_display}#{rarity_tag}#{qty_tag}"
      end
      lines.join("\n")
    end

    def take_command(item_name)
      return "<span style='color: #fbbf24;'>Take what?</span>" if item_name.empty?

      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless room

      item = room.grid_items.in_room(room).find_by("LOWER(name) = ?", item_name.downcase)
      return "<span style='color: #f87171;'>You don't see '#{h(item_name)}' here.</span>" unless item

      item.update!(grid_hackr: hackr, room: nil)

      increment_stat!("items_taken")

      output = "<span style='color: #34d399;'>You take the </span>#{item.unicorn? ? item.rainbow_name_html : "<span style='color: #34d399;'>#{h(item.name)}</span>"}<span style='color: #34d399;'>.</span>"
      notifications = achievement_checker.check(:take_item, item_name: item.name)
      notifications += achievement_checker.check(:items_collected)
      notifications += achievement_checker.check(:rarity_owned, rarity: item.rarity) if item.rarity.present?
      output = append_notifications(output, notifications)

      {
        output: output,
        event: {
          type: "take",
          hackr_alias: hackr.hackr_alias,
          item_name: item.name,
          room_id: room.id
        }
      }
    end

    def drop_command(item_name)
      return "<span style='color: #fbbf24;'>Drop what?</span>" if item_name.empty?

      item = hackr.grid_items.find_by("LOWER(name) = ?", item_name.downcase)
      return "<span style='color: #f87171;'>You don't have '#{h(item_name)}'.</span>" unless item

      room = hackr.current_room
      item.update!(room: room, grid_hackr: nil)

      {
        output: "<span style='color: #34d399;'>You drop the </span>#{item.unicorn? ? item.rainbow_name_html : "<span style='color: #34d399;'>#{h(item.name)}</span>"}<span style='color: #34d399;'>.</span>",
        event: {
          type: "drop",
          hackr_alias: hackr.hackr_alias,
          item_name: item.name,
          room_id: room.id
        }
      }
    end

    def examine_command(target)
      return "<span style='color: #fbbf24;'>Examine what?</span>" if target.empty?

      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless room

      # Check items in room
      item = room.grid_items.in_room(room).find_by("LOWER(name) = ?", target.downcase)
      return "<span style='color: #d0d0d0;'>#{codex_linkify(item.description)}</span>" if item

      # Check items in inventory
      item = hackr.grid_items.find_by("LOWER(name) = ?", target.downcase)
      return "<span style='color: #d0d0d0;'>#{codex_linkify(item.description)}</span>" if item

      # Check Mobs
      mob = room.grid_mobs.find_by("LOWER(name) = ?", target.downcase)
      return "<span style='color: #d0d0d0;'>#{codex_linkify(mob.description)}</span>" if mob

      # Check hackrs in room (or self)
      target_hackr = if target.downcase == hackr.hackr_alias.downcase
        hackr
      else
        room.grid_hackrs.recently_active.find_by("LOWER(hackr_alias) = ?", target.downcase)
      end
      return examine_hackr(target_hackr) if target_hackr

      "<span style='color: #f87171;'>You don't see '#{h(target)}' here.</span>"
    end

    def talk_command(npc_name)
      # Handle "talk to <npc>" syntax
      npc_name = npc_name.sub(/^to\s+/, "")
      return "<span style='color: #fbbf24;'>Talk to whom?</span>" if npc_name.empty?

      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless room

      mob = room.grid_mobs.find_by("LOWER(name) = ?", npc_name.downcase)
      return "<span style='color: #f87171;'>You don't see '#{h(npc_name)}' here.</span>" unless mob
      return "<span style='color: #9ca3af;'>#{h(mob.name)} doesn't seem interested in talking.</span>" if mob.dialogue_tree.blank?

      dialogue = mob.dialogue_tree
      content = []
      content << "<span style='color: #c084fc;'>#{h(mob.name)}</span>: <span style='color: #60a5fa;'>\"#{h(dialogue["greeting"])}\"</span>"

      if dialogue["topics"].present? && dialogue["topics"].any?
        content << ""
        content << "<span style='color: #9ca3af;'>You can ask about:</span> <span style='color: #fbbf24;'>#{dialogue["topics"].keys.map { |k| h(k) }.join(", ")}</span>"
      end

      increment_stat!("npcs_talked")

      output = dialogue_box(content.join("\n"))
      notifications = achievement_checker.check(:talk_npc, npc_name: mob.name)
      append_notifications(output, notifications)
    end

    def ask_command(args)
      # Parse "ask <npc> about <topic>"
      return "<span style='color: #fbbf24;'>Ask whom about what? Usage: ask &lt;npc&gt; about &lt;topic&gt;</span>" if args.length < 3

      # Handle both "ask Synthia about mission" and "ask <npc> <topic>" formats
      about_index = args.index { |word| word.downcase == "about" }

      if about_index
        npc_name = args[0...about_index].join(" ")
        topic = args[(about_index + 1)..]&.join(" ")
      else
        npc_name = args.first
        topic = args[1..].join(" ")
      end

      return "<span style='color: #fbbf24;'>Ask whom about what?</span>" if npc_name.blank? || topic.blank?

      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless room

      mob = room.grid_mobs.find_by("LOWER(name) = ?", npc_name.downcase)
      return "<span style='color: #f87171;'>You don't see '#{h(npc_name)}' here.</span>" unless mob
      return "<span style='color: #9ca3af;'>#{h(mob.name)} doesn't seem interested in talking.</span>" if mob.dialogue_tree.blank?

      dialogue = mob.dialogue_tree
      topics = dialogue["topics"] || {}

      # Try exact match first, then case-insensitive match
      response = topics[topic] || topics[topic.downcase] || topics.find { |k, v| k.downcase == topic.downcase }&.last

      if response
        content = "<span style='color: #c084fc;'>#{h(mob.name)}</span>: <span style='color: #60a5fa;'>\"#{h(response)}\"</span>"
      else
        available = topics.keys.map { |k| h(k) }.join(", ")
        content = "<span style='color: #c084fc;'>#{h(mob.name)}</span> doesn't know about '#{h(topic)}'. <span style='color: #9ca3af;'>Try asking about:</span> <span style='color: #fbbf24;'>#{available}</span>"
      end
      dialogue_box(content)
    end

    def help_command
      <<~HELP
        <span style='color: #22d3ee; font-weight: bold;'>Available Commands:</span>

        <span style='color: #fbbf24;'>Navigation:</span>
          <span style='color: #34d399;'>look, l</span>                 - Look around the room
          <span style='color: #34d399;'>go &lt;direction&gt;</span>          - Move in a direction
          <span style='color: #34d399;'>north, n / south, s</span>     - Move north/south
          <span style='color: #34d399;'>east, e / west, w</span>       - Move east/west
          <span style='color: #34d399;'>up, u / down, d</span>         - Move up/down

        <span style='color: #fbbf24;'>Items:</span>
          <span style='color: #34d399;'>inventory, inv, i</span>       - View your inventory
          <span style='color: #34d399;'>take &lt;item&gt;</span>             - Pick up an item
          <span style='color: #34d399;'>drop &lt;item&gt;</span>             - Drop an item
          <span style='color: #34d399;'>use &lt;item&gt;</span>              - Use an item
          <span style='color: #34d399;'>salvage &lt;item&gt;</span>          - Break down an item for XP
          <span style='color: #34d399;'>examine &lt;target&gt;, x</span>     - Examine item, NPC, or hackr

        <span style='color: #fbbf24;'>NPCs:</span>
          <span style='color: #34d399;'>talk &lt;npc&gt;</span>              - Talk to an NPC
          <span style='color: #34d399;'>ask &lt;npc&gt; about &lt;topic&gt;</span> - Ask an NPC about a topic

        <span style='color: #fbbf24;'>Social:</span>
          <span style='color: #34d399;'>say &lt;message&gt;</span>           - Say something in the room
          <span style='color: #34d399;'>who</span>                     - See who's online

        <span style='color: #fbbf24;'>Operative:</span>
          <span style='color: #34d399;'>stat, stats</span>             - View your operative profile
          <span style='color: #34d399;'>clear, cls</span>              - Clear the screen
          <span style='color: #34d399;'>help, ?</span>                 - Show this help message
      HELP
    end

    def who_command
      online = GridHackr.online.order(:hackr_alias)
      if online.any?
        "<span style='color: #fbbf24;'>Online Hackrs:</span>\n" + online.map { |h| "  - <span style='color: #a78bfa;'>#{h.hackr_alias}</span> <span style='color: #9ca3af;'>(#{h.current_room&.name || "nowhere"})</span>" }.join("\n")
      else
        "<span style='color: #9ca3af;'>No hackrs are currently online.</span>"
      end
    end

    def clear_command
      {
        output: "",
        event: {type: "clear"}
      }
    end

    def stat_command
      s = hackr.current_stats
      cl = hackr.stat("clearance")
      xp = hackr.stat("xp")
      next_threshold = GridHackr::Stats.xp_for_clearance(cl + 1)
      xp_to_next = (cl < GridHackr::Stats::MAX_CLEARANCE) ? next_threshold - xp : nil

      achievements = hackr.grid_hackr_achievements.includes(:grid_achievement).order(:awarded_at).to_a

      output = []
      output << "\n<span style='color: #a78bfa;'>════════════════════════════════════════</span>"
      output << "<span style='color: #22d3ee; font-weight: bold;'>OPERATIVE FILE :: #{h(hackr.hackr_alias)}</span>"
      output << "<span style='color: #a78bfa;'>════════════════════════════════════════</span>"
      output << ""
      output << "<span style='color: #fbbf24;'>CLEARANCE:</span> <span style='color: #22d3ee;'>#{cl}</span>  <span style='color: #fbbf24;'>XP:</span> <span style='color: #34d399;'>#{xp}</span>#{xp_to_next ? " <span style='color: #6b7280;'>(#{xp_to_next} to next)</span>" : " <span style='color: #fbbf24;'>[MAX]</span>"}"
      output << ""
      output << "<span style='color: #fbbf24;'>VITALS:</span>"
      output << "  <span style='color: #34d399;'>HEALTH      #{s["health"]}/100</span>"
      output << "  <span style='color: #60a5fa;'>ENERGY      #{s["energy"]}/100</span>"
      output << "  <span style='color: #c084fc;'>PSYCHE      #{s["psyche"]}/100</span>"
      output << "  <span style='color: #f59e0b;'>INSPIRATION #{s["inspiration"]}/100</span>"

      if achievements.any?
        output << ""
        output << "<span style='color: #fbbf24;'>ACHIEVEMENTS (#{achievements.size}):</span>"
        achievements.each do |ha|
          a = ha.grid_achievement
          icon = a.badge_icon.present? ? "#{a.badge_icon} " : ""
          output << "  #{icon}<span style='color: #d0d0d0;'>#{h(a.name)}</span> <span style='color: #6b7280;'>(+#{a.xp_reward}xp)</span>"
        end
      end

      output << "<span style='color: #a78bfa;'>════════════════════════════════════════</span>"
      output.join("\n")
    end

    def use_command(item_name)
      return "<span style='color: #fbbf24;'>Use what?</span>" if item_name.empty?

      item = hackr.grid_items.find_by("LOWER(name) = ?", item_name.downcase)
      return "<span style='color: #f87171;'>You don't have '#{h(item_name)}'.</span>" unless item

      saved_name = item.name
      result = apply_item_effect(item)
      increment_stat!("use_count")

      # Consume if consumable
      if item.item_type == "consumable"
        if item.quantity > 1
          item.update!(quantity: item.quantity - 1)
        else
          item.destroy!
        end
      end

      notifications = achievement_checker.check(:use_item, item_name: saved_name)
      output = append_notifications(result, notifications)
      {output: output, event: nil}
    end

    def salvage_command(item_name)
      return "<span style='color: #fbbf24;'>Salvage what?</span>" if item_name.empty?

      item = hackr.grid_items.find_by("LOWER(name) = ?", item_name.downcase)
      return "<span style='color: #f87171;'>You don't have '#{h(item_name)}'.</span>" unless item

      xp_amount = [item.value, 1].max
      item_styled = item.unicorn? ? item.rainbow_name_html : h(item.name)
      if item.quantity > 1
        item.update!(quantity: item.quantity - 1)
      else
        item.destroy!
      end

      increment_stat!("salvage_count")
      xp_result = hackr.grant_xp!(xp_amount)

      level_msg = xp_result[:leveled_up] ? "\n<span style='color: #fbbf24; font-weight: bold;'>▲ CLEARANCE INCREASED TO #{xp_result[:new_clearance]}!</span>" : ""
      output = "<span style='color: #34d399;'>You salvage </span>#{item_styled}<span style='color: #34d399;'>. +#{xp_amount} XP.</span>#{level_msg}"

      notifications = achievement_checker.check(:salvage_item)
      notifications += achievement_checker.check(:salvage_count)
      output = append_notifications(output, notifications)
      {output: output, event: nil}
    end

    def apply_item_effect(item)
      props = (item.properties || {}).with_indifferent_access
      effect_type = props[:effect_type]

      case effect_type
      when "heal"
        amount = props[:amount].to_i
        new_val = hackr.adjust_vital!("health", amount)
        "<span style='color: #34d399;'>You use #{h(item.name)}. Health restored by #{amount}. (#{new_val}/100)</span>"
      when "energize"
        amount = props[:amount].to_i
        new_val = hackr.adjust_vital!("energy", amount)
        "<span style='color: #60a5fa;'>You use #{h(item.name)}. Energy restored by #{amount}. (#{new_val}/100)</span>"
      when "psyche_boost"
        amount = props[:amount].to_i
        new_val = hackr.adjust_vital!("psyche", amount)
        "<span style='color: #c084fc;'>You use #{h(item.name)}. Psyche boosted by #{amount}. (#{new_val}/100)</span>"
      when "inspire"
        amount = props[:amount].to_i
        new_val = hackr.adjust_vital!("inspiration", amount)
        "<span style='color: #f59e0b;'>You use #{h(item.name)}. Inspiration surges by #{amount}. (#{new_val}/100)</span>"
      when "xp_boost"
        amount = props[:amount].to_i
        result = hackr.grant_xp!(amount)
        level_msg = result[:leveled_up] ? "\n<span style='color: #fbbf24; font-weight: bold;'>▲ CLEARANCE INCREASED TO #{result[:new_clearance]}!</span>" : ""
        "<span style='color: #fbbf24;'>You use #{h(item.name)}. +#{amount} XP.#{level_msg}</span>"
      else
        "<span style='color: #9ca3af;'>You use #{h(item.name)}. Nothing happens.</span>"
      end
    end

    def examine_hackr(target_hackr)
      cl = target_hackr.stat("clearance")
      achievements = target_hackr.grid_achievements.order(:name)

      output = []
      output << "<span style='color: #a78bfa; font-weight: bold;'>#{h(target_hackr.hackr_alias)}</span> <span style='color: #9ca3af;'>:: CLEARANCE #{cl}</span>"

      if achievements.any?
        badges = achievements.map { |a|
          icon = a.badge_icon.present? ? "#{a.badge_icon} " : ""
          "<span style='color: #fbbf24;'>#{icon}#{h(a.name)}</span>"
        }.join(", ")
        output << "<span style='color: #9ca3af;'>Badges:</span> #{badges}"
      else
        output << "<span style='color: #6b7280;'>No badges earned yet.</span>"
      end

      output.join("\n")
    end

    def dialogue_box(content)
      # Create a thin-bordered box around dialogue content
      # Add blank line before box, strip content to avoid blank lines inside
      "\n<div style='border: 1px solid #666; padding: 10px; margin: 5px 0; background: #0d0d0d;'>#{content.strip}</div>"
    end

    # --- Progression helpers ---

    def achievement_checker
      @achievement_checker ||= Grid::AchievementChecker.new(hackr)
    end

    def increment_stat!(key, amount = 1)
      current = hackr.stat(key) || 0
      hackr.set_stat!(key, current + amount)
    end

    def append_notifications(output, notifications)
      return output if notifications.empty?
      [output, *notifications].compact.join("\n")
    end
  end
end
