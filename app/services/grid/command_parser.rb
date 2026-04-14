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
      when "stat", "stats", "st"
        stat_command
      when "rep", "reputation", "standing"
        rep_command
      when "use"
        use_command(args.join(" "))
      when "salvage"
        salvage_command(args.join(" "))
      when "cache"
        cache_command(args)
      when "caches", "cred"
        cache_list_command
      when "chain"
        chain_command(args)
      when "rig"
        rig_command(args)
      when "shop", "browse"
        shop_command
      when "buy", "purchase"
        buy_command(args.join(" "))
      when "sell"
        sell_command(args.join(" "))
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

      # Clearance gate
      if new_room.clearance_gated?
        hackr_clearance = hackr.stat("clearance")
        if hackr_clearance < new_room.min_clearance
          return "<span style='color: #f87171;'>ACCESS DENIED. Clearance #{new_room.min_clearance}+ required. You are Clearance #{hackr_clearance}.</span>"
        end
      end
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
      return examine_item(item) if item

      # Check items in inventory
      item = hackr.grid_items.find_by("LOWER(name) = ?", target.downcase)
      return examine_item(item) if item

      # Check vendor shop listings (respecting per-listing clearance gate)
      vendor = room.grid_mobs.find_by(mob_type: "vendor")
      if vendor
        clearance = hackr.stat("clearance")
        listing = vendor.grid_shop_listings.where(active: true)
          .where("min_clearance <= ?", clearance)
          .find_by("LOWER(name) = ?", target.downcase)
        if listing
          price = Grid::ShopService.effective_price(listing: listing, mob: vendor, clearance: clearance)
          return examine_listing(listing, price)
        end
      end

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
      rep_notif = grant_faction_rep(mob.grid_faction, 1, reason: "talk:#{slugify(mob.name)}", source: mob)
      notifications = achievement_checker.check(:talk_npc, npc_name: mob.name)
      notifications.unshift(rep_notif) if rep_notif
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
          <span style='color: #34d399;'>look, l</span>                   - Look around the room
          <span style='color: #34d399;'>go &lt;direction&gt;</span>            - Move in a direction
          <span style='color: #34d399;'>north, n / south, s</span>       - Move north/south
          <span style='color: #34d399;'>east, e / west, w</span>         - Move east/west
          <span style='color: #34d399;'>up, u / down, d</span>           - Move up/down

        <span style='color: #fbbf24;'>Items:</span>
          <span style='color: #34d399;'>inventory, inv, i</span>         - View your inventory
          <span style='color: #34d399;'>take &lt;item&gt;</span>               - Pick up an item
          <span style='color: #34d399;'>drop &lt;item&gt;</span>               - Drop an item
          <span style='color: #34d399;'>use &lt;item&gt;</span>                - Use an item
          <span style='color: #34d399;'>salvage &lt;item&gt;</span>            - Break down an item for XP
          <span style='color: #34d399;'>examine &lt;target&gt;, x</span>       - Examine item, NPC, or hackr

        <span style='color: #fbbf24;'>NPCs:</span>
          <span style='color: #34d399;'>talk &lt;npc&gt;</span>                - Talk to an NPC
          <span style='color: #34d399;'>ask &lt;npc&gt; about &lt;topic&gt;</span>   - Ask an NPC about a topic

        <span style='color: #fbbf24;'>Commerce:</span>
          <span style='color: #34d399;'>shop, browse</span>              - View vendor inventory &amp; prices
          <span style='color: #34d399;'>buy &lt;item&gt;</span>                - Purchase an item from vendor
          <span style='color: #34d399;'>sell &lt;item&gt;</span>               - Sell an item to vendor

        <span style='color: #fbbf24;'>Economy:</span>
          <span style='color: #34d399;'>cache</span>                     - List your caches
          <span style='color: #34d399;'>cache create</span>              - Create a new cache
          <span style='color: #34d399;'>cache balance [addr]</span>      - Check balance
          <span style='color: #34d399;'>cache history [addr]</span>      - Transaction history
          <span style='color: #34d399;'>cache send &lt;amt&gt; &lt;to&gt;</span>     - Send CRED (opts: from &lt;src&gt;, memo &lt;text&gt;)
          <span style='color: #34d399;'>cache default &lt;addr&gt;</span>      - Set default cache
          <span style='color: #34d399;'>cache name &lt;addr&gt; &lt;nick&gt;</span>  - Nickname a cache
          <span style='color: #34d399;'>cache abandon &lt;addr&gt;</span>      - Abandon a cache (WARNING: This is irreversible)

        <span style='color: #fbbf24;'>Ledger:</span>
          <span style='color: #34d399;'>chain latest</span>              - Recent global transactions
          <span style='color: #34d399;'>chain tx &lt;hash&gt;</span>           - Look up a transaction
          <span style='color: #34d399;'>chain cache &lt;addr&gt;</span>        - Public history for a cache
          <span style='color: #34d399;'>chain supply</span>              - CRED supply overview

        <span style='color: #fbbf24;'>Mining:</span>
          <span style='color: #34d399;'>rig</span>                       - Mining rig status
          <span style='color: #34d399;'>rig on / rig off</span>          - Toggle mining
          <span style='color: #34d399;'>rig install &lt;item&gt;</span>        - Install component (rig must be off)
          <span style='color: #34d399;'>rig uninstall &lt;item&gt;</span>      - Remove component (rig must be off)
          <span style='color: #34d399;'>rig inspect</span>               - Detailed rig view

        <span style='color: #fbbf24;'>Social:</span>
          <span style='color: #34d399;'>say &lt;message&gt;</span>             - Say something in the room
          <span style='color: #34d399;'>who</span>                       - See who's online

        <span style='color: #fbbf24;'>Operative:</span>
          <span style='color: #34d399;'>stat, stats</span>               - View your operative profile
          <span style='color: #34d399;'>rep, reputation</span>           - View faction standings in detail
          <span style='color: #34d399;'>clear, cls</span>                - Clear the screen
          <span style='color: #34d399;'>help, ?</span>                   - Show this help message
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
      default_cache = hackr.default_cache
      default_balance = default_cache&.balance || 0
      total_balance = hackr.grid_caches.sum { |c| c.balance }
      cache_label = if default_cache
        default_cache.nickname.present? ? default_cache.nickname : default_cache.address
      else
        "none"
      end
      output << "<span style='color: #fbbf24;'>CLEARANCE:</span> <span style='color: #22d3ee;'>#{cl}</span>  <span style='color: #fbbf24;'>XP:</span> <span style='color: #34d399;'>#{xp}</span>#{xp_to_next ? " <span style='color: #6b7280;'>(#{xp_to_next} to next)</span>" : " <span style='color: #fbbf24;'>[MAX]</span>"}"
      output << "<span style='color: #fbbf24;'>CRED:</span> <span style='color: #34d399;'>#{format_cred(default_balance)}</span> <span style='color: #6b7280;'>(default cache: #{h(cache_label)})</span>"
      output << "<span style='color: #fbbf24;'>CRED:</span> <span style='color: #34d399;'>#{format_cred(total_balance)}</span> <span style='color: #6b7280;'>(total across all caches)</span>"
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

      standings = reputation_service.faction_standings
      if standings.any?
        output << ""
        output << "<span style='color: #fbbf24;'>STANDING:</span>"
        max_name = standings.map { |s| s[:faction].display_name.length }.max || 0
        standings.each do |s|
          output << "  #{format_rep_row(s, name_width: max_name, compact: true)}"
        end
        output << "  <span style='color: #6b7280;'>(use 'rep' for the full standing report)</span>"
      end

      output << "<span style='color: #a78bfa;'>════════════════════════════════════════</span>"
      output.join("\n")
    end

    def rep_command
      standings = reputation_service.faction_standings(include_zero: true)
      output = []
      output << "\n<span style='color: #a78bfa;'>════════════════════════════════════════</span>"
      output << "<span style='color: #22d3ee; font-weight: bold;'>STANDING REPORT :: #{h(hackr.hackr_alias)}</span>"
      output << "<span style='color: #a78bfa;'>════════════════════════════════════════</span>"

      if standings.empty?
        output << "<span style='color: #9ca3af;'>No factions on file. The Grid doesn't know you yet.</span>"
        output << "<span style='color: #a78bfa;'>════════════════════════════════════════</span>"
        return output.join("\n")
      end

      # Walk the parent→child hierarchy recursively so arbitrary depth renders.
      # Orphan rows (parent_id set but parent not in the standings list, e.g.,
      # filtered out or deleted) are promoted to roots. Cycle guard defends
      # against pathological data — real prevention is at the model validator.
      children_by_parent = standings.group_by { |s| s[:faction].parent_id }
      standing_ids = standings.map { |s| s[:faction].id }.to_set
      roots = standings.select { |s| s[:faction].parent_id.nil? || !standing_ids.include?(s[:faction].parent_id) }

      ordered = []
      max_name = 0
      walk = lambda do |standing, depth, visited|
        fid = standing[:faction].id
        next if visited.include?(fid)
        visited += [fid]
        ordered << [standing, depth]
        indent_len = (depth > 0) ? (2 * (depth - 1) + 3) : 0
        max_name = [max_name, indent_len + standing[:faction].display_name.length].max
        (children_by_parent[fid] || []).each { |child| walk.call(child, depth + 1, visited) }
      end
      roots.each { |s| walk.call(s, 0, []) }

      ordered.each do |(standing, depth)|
        output << format_rep_row(standing, name_width: max_name, depth: depth)
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

    def examine_item(item)
      output = "<span style='color: #d0d0d0;'>#{codex_linkify(item.description)}</span>"
      if item.component? && item.rate_multiplier
        props = item.properties || {}
        slot = props["slot"]&.upcase || "UNKNOWN"
        output += "\n<span style='color: #22d3ee;'>Slot: #{slot}</span>"
        output += " <span style='color: #fbbf24;'>Multiplier: x#{item.rate_multiplier}</span>"
        if slot == "MOTHERBOARD"
          output += "\n<span style='color: #9ca3af;'>Slots: CPU #{props["cpu_slots"] || 0} / GPU #{props["gpu_slots"] || 0} / RAM #{props["ram_slots"] || 0}</span>"
        end
      end
      output
    end

    def examine_listing(listing, effective_price)
      color = listing.rarity_color
      rarity_tag = listing.rarity ? " <span style='color: #{color};'>[#{listing.rarity_label}]</span>" : ""
      output = "<span style='color: #d0d0d0;'>#{codex_linkify(listing.description)}</span>#{rarity_tag}"
      output += "\n<span style='color: #6b7280;'>Buy: <span style='color: #34d399;'>#{format_cred(effective_price)} CRED</span> / Sell: #{format_cred(listing.sell_price)} CRED</span>"
      if listing.item_type == "component"
        props = listing.properties || {}
        slot = props["slot"]&.upcase || "UNKNOWN"
        mult = props["rate_multiplier"] || 1.0
        output += "\n<span style='color: #22d3ee;'>Slot: #{slot}</span>"
        output += " <span style='color: #fbbf24;'>Multiplier: x#{mult}</span>"
        if slot == "MOTHERBOARD"
          output += "\n<span style='color: #9ca3af;'>Slots: CPU #{props["cpu_slots"] || 0} / GPU #{props["gpu_slots"] || 0} / RAM #{props["ram_slots"] || 0}</span>"
        end
      end
      output
    end

    def dialogue_box(content)
      # Create a thin-bordered box around dialogue content
      # Add blank line before box, strip content to avoid blank lines inside
      "\n<div style='border: 1px solid #666; padding: 10px; margin: 5px 0; background: #0d0d0d;'>#{content.strip}</div>"
    end

    # --- Shop commands ---

    def shop_command
      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless room

      vendor = room.grid_mobs.find_by(mob_type: "vendor")
      return "<span style='color: #9ca3af;'>There's no vendor here.</span>" unless vendor

      items = Grid::ShopService.listing_display(mob: vendor, hackr: hackr)

      if items.empty?
        return dialogue_box(
          "<span style='color: #c084fc;'>#{h(vendor.name)}</span>: <span style='color: #60a5fa;'>\"Nothing for you right now.\"</span>"
        )
      end

      output = []
      output << "\n<span style='color: #a78bfa;'>════════════════════════════════════════════════════════════════</span>"

      if vendor.black_market?
        clearance = hackr.stat("clearance")
        output << "<span style='color: #f87171; font-weight: bold;'>⚠ BLACK MARKET</span> <span style='color: #9ca3af;'>:: #{h(vendor.name)}</span>"
        output << "<span style='color: #6b7280;'>Prices adjusted for CLEARANCE #{clearance}. Higher clearance = better rates.</span>"
      else
        output << "<span style='color: #22d3ee; font-weight: bold;'>VENDOR :: #{h(vendor.name)}</span>"
      end

      output << ""

      # Table
      rows = items.map do |entry|
        listing = entry[:listing]
        price = entry[:effective_price]
        color = listing.rarity_color
        name_display = "<span style='color: #{color};'>#{h(listing.name)}</span>"
        rarity_display = "<span style='color: #{color};'>[#{listing.rarity_label}]</span>"

        price_color = entry[:affordable] ? "#34d399" : "#f87171"
        price_display = "<span style='color: #{price_color};'>#{format_cred(price)}</span>"

        stock_display = if listing.unlimited_stock?
          "<span style='color: #34d399;'>∞</span>"
        elsif listing.out_of_stock?
          "<span style='color: #f87171;'>OUT</span>"
        else
          "<span style='color: #fbbf24;'>#{listing.stock}</span>"
        end

        "<tr><td style='padding: 2px 12px 2px 0;'>#{name_display}</td>" \
        "<td style='padding: 2px 12px 2px 0;'>#{rarity_display}</td>" \
        "<td style='padding: 2px 12px 2px 0; text-align: right;'>#{price_display}</td>" \
        "<td style='padding: 2px 0; text-align: center;'>#{stock_display}</td></tr>"
      end

      table = "<table style='border-collapse: collapse; margin: 0 8px;'>" \
        "<tr style='color: #6b7280;'>" \
        "<th style='text-align: left; padding: 2px 12px 2px 0; border-bottom: 1px solid #333;'>Item</th>" \
        "<th style='text-align: left; padding: 2px 12px 2px 0; border-bottom: 1px solid #333;'>Rarity</th>" \
        "<th style='text-align: right; padding: 2px 12px 2px 0; border-bottom: 1px solid #333;'>Price</th>" \
        "<th style='text-align: center; padding: 2px 0; border-bottom: 1px solid #333;'>Stock</th>" \
        "</tr>#{rows.join}</table>"
      output << table

      output << ""
      balance = hackr.default_cache&.balance || 0
      output << "<span style='color: #6b7280;'>Your CRED: #{format_cred(balance)}. Use 'buy &lt;item&gt;' to purchase, 'sell &lt;item&gt;' to sell.</span>"
      output << "<span style='color: #a78bfa;'>════════════════════════════════════════════════════════════════</span>"

      output.join("\n")
    end

    def buy_command(item_name)
      return "<span style='color: #fbbf24;'>Buy what? Usage: buy &lt;item&gt;</span>" if item_name.empty?

      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless room

      vendor = room.grid_mobs.find_by(mob_type: "vendor")
      return "<span style='color: #9ca3af;'>There's no vendor here.</span>" unless vendor

      result = Grid::ShopService.buy!(hackr: hackr, mob: vendor, item_name: item_name)

      item = result[:item]
      color = item.rarity_color
      name_display = item.unicorn? ? item.rainbow_name_html : "<span style='color: #{color};'>#{h(item.name)}</span>"

      output = "<span style='color: #34d399;'>Purchased </span>#{name_display}<span style='color: #34d399;'> for <span style='color: #fbbf24;'>#{format_cred(result[:price_paid])} CRED</span>. Balance: #{format_cred(result[:new_balance])} CRED.</span>"

      rep_notif = grant_faction_rep(vendor.grid_faction, 2, reason: "buy:#{slugify(item.name)}", source: vendor)
      notifications = achievement_checker.check(:purchase_item, item_name: item.name)
      notifications.unshift(rep_notif) if rep_notif
      output = append_notifications(output, notifications)
      {output: output, event: nil}
    rescue Grid::ShopService::AccessDenied => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue Grid::ShopService::ItemNotFound => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue Grid::ShopService::InsufficientStock => e
      "<span style='color: #fbbf24;'>#{h(e.message)}</span>"
    rescue Grid::ShopService::InsufficientBalance => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    end

    def sell_command(item_name)
      return "<span style='color: #fbbf24;'>Sell what? Usage: sell &lt;item&gt;</span>" if item_name.empty?

      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless room

      vendor = room.grid_mobs.find_by(mob_type: "vendor")
      return "<span style='color: #9ca3af;'>There's no vendor here.</span>" unless vendor

      result = Grid::ShopService.sell!(hackr: hackr, mob: vendor, item_name: item_name)

      "<span style='color: #34d399;'>Sold </span><span style='color: #d0d0d0;'>#{h(result[:item_name])}</span><span style='color: #34d399;'> for <span style='color: #fbbf24;'>#{format_cred(result[:sell_price])} CRED</span>. Balance: #{format_cred(result[:new_balance])} CRED.</span>"
    rescue Grid::ShopService::AccessDenied => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue Grid::ShopService::ItemNotFound => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue Grid::TransactionService::InsufficientBalance
      "<span style='color: #f87171;'>The vendor can't afford to buy that right now.</span>"
    end

    # --- Economy commands ---

    def cache_command(args)
      subcmd = args.first&.downcase
      sub_args = args[1..] || []

      case subcmd
      when nil, "list"
        cache_list_command
      when "create"
        cache_create_command
      when "balance"
        cache_balance_command(sub_args.first)
      when "history"
        cache_history_command(sub_args.first)
      when "send"
        cache_send_command(sub_args)
      when "default"
        cache_default_command(sub_args.first)
      when "abandon"
        cache_abandon_command(sub_args.first)
      when "name"
        cache_name_command(sub_args)
      else
        "<span style='color: #f87171;'>Unknown cache command: #{h(subcmd)}. Try 'help' for usage.</span>"
      end
    end

    def cache_list_command
      caches = hackr.grid_caches.order(:created_at)
      return "<span style='color: #9ca3af;'>You have no caches. Use 'cache create' to create one.</span>" if caches.empty?

      # Pre-compute balances for right-alignment
      cache_data = caches.map do |cache|
        {cache: cache, balance_str: format_cred(cache.balance)}
      end
      max_balance_len = cache_data.map { |d| d[:balance_str].length }.max
      max_nick_len = caches.filter_map { |c| c.nickname&.length }.max || 0
      nick_col = [max_nick_len, 8].max # minimum column width

      lines = ["<span style='color: #fbbf24;'>Your Caches:</span>"]
      cache_data.each do |data|
        cache = data[:cache]
        bal = data[:balance_str].rjust(max_balance_len)
        nick = cache.nickname.present? ? h(cache.nickname).ljust(nick_col) : "—".ljust(nick_col)
        flags = []
        flags << "<span style='color: #22d3ee;'>DEFAULT</span>" if cache.is_default?
        flags << "<span style='color: #f87171;'>ABANDONED</span>" if cache.abandoned?
        flag_str = flags.any? ? " #{flags.join(" ")}" : ""

        lines << "  <span style='color: #34d399;'>#{cache.address}</span>  <span style='color: #a78bfa;'>#{nick}</span>  <span style='color: #34d399;'>#{bal}</span> <span style='color: #6b7280;'>CRED</span>#{flag_str}"
      end
      lines.join("\n")
    end

    def cache_create_command
      address = GridCache.generate_address
      hackr.grid_caches.create!(address: address, status: "active")
      "<span style='color: #34d399;'>Cache created:</span> <span style='color: #22d3ee;'>#{address}</span>\n<span style='color: #9ca3af;'>Use 'cache name #{address} &lt;nickname&gt;' to give it a name.</span>"
    end

    def cache_balance_command(identifier)
      cache = if identifier.present?
        resolve_own_cache(identifier)
      else
        hackr.default_cache
      end
      return "<span style='color: #f87171;'>Cache not found.</span>" unless cache

      "<span style='color: #fbbf24;'>#{cache.display_name}:</span> <span style='color: #34d399;'>#{format_cred(cache.balance)} CRED</span>"
    end

    def cache_history_command(identifier)
      cache = if identifier.present?
        resolve_own_cache(identifier)
      else
        hackr.default_cache
      end
      return "<span style='color: #f87171;'>Cache not found.</span>" unless cache

      txs = GridTransaction.for_cache(cache).recent.limit(15)
      return "<span style='color: #9ca3af;'>No transactions found for #{cache.display_name}.</span>" if txs.empty?

      lines = ["<span style='color: #fbbf24;'>Transaction History — #{cache.display_name}:</span>"]
      txs.each do |tx|
        direction = (tx.to_cache_id == cache.id) ? "+" : "-"
        color = (direction == "+") ? "#34d399" : "#f87171"
        other = (direction == "+") ? tx.from_cache.address : tx.to_cache.address
        memo_tag = tx.memo.present? ? " <span style='color: #6b7280;'>#{h(tx.memo)}</span>" : ""
        lines << "  <span style='color: #6b7280;'>[#{grid_time(tx.created_at)}]</span> <span style='color: #{color};'>#{direction}#{format_cred(tx.amount)}</span> <span style='color: #9ca3af;'>#{other}</span>#{memo_tag} <span style='color: #4b5563;'>#{tx.short_hash}</span>"
      end
      lines.join("\n")
    end

    def cache_send_command(args)
      if args.length < 2
        return "<span style='color: #fbbf24;'>Usage: cache send &lt;amount&gt; &lt;to&gt; [from &lt;source&gt;] [memo &lt;text&gt;]</span>"
      end

      amount_str = args[0]
      target_identifier = args[1]
      remaining = args[2..] || []

      # Parse optional "from <source>" and "memo <text>" from remaining args
      from_identifier = nil
      memo = nil

      memo_index = remaining.index { |w| w.downcase == "memo" }
      if memo_index
        memo = remaining[(memo_index + 1)..].join(" ").presence
        remaining = remaining[0...memo_index]
      end

      if remaining.length >= 2 && remaining[0]&.downcase == "from"
        from_identifier = remaining[1]
      end

      amount = amount_str.to_i
      return "<span style='color: #f87171;'>Amount must be a positive whole number.</span>" unless amount_str.match?(/\A\d+\z/) && amount.positive?

      from_cache = if from_identifier
        resolve_own_cache(from_identifier)
      else
        hackr.default_cache
      end
      return "<span style='color: #f87171;'>Source cache not found.</span>" unless from_cache

      to_cache = resolve_any_cache(target_identifier)
      return "<span style='color: #f87171;'>Target cache not found: #{h(target_identifier)}</span>" unless to_cache
      return "<span style='color: #f87171;'>Cannot send to the same cache.</span>" if from_cache.id == to_cache.id

      tx = Grid::TransactionService.transfer!(from_cache: from_cache, to_cache: to_cache, amount: amount, memo: memo)
      "<span style='color: #34d399;'>Sent #{format_cred(amount)} CRED to #{to_cache.address}.</span>\n<span style='color: #6b7280;'>TX: #{tx.short_hash}</span>"
    rescue Grid::TransactionService::InsufficientBalance
      "<span style='color: #f87171;'>Insufficient balance. Cache has #{format_cred(from_cache.balance)} CRED.</span>"
    rescue Grid::TransactionService::InvalidTransfer => e
      "<span style='color: #f87171;'>Transfer failed: #{h(e.message)}</span>"
    end

    def cache_default_command(identifier)
      return "<span style='color: #fbbf24;'>Usage: cache default &lt;address_or_nickname&gt;</span>" if identifier.blank?

      cache = resolve_own_cache(identifier)
      return "<span style='color: #f87171;'>Cache not found.</span>" unless cache
      return "<span style='color: #f87171;'>Cannot set an abandoned cache as default.</span>" if cache.abandoned?

      ActiveRecord::Base.transaction do
        hackr.grid_caches.where(is_default: true).update_all(is_default: false)
        cache.update!(is_default: true)
      end
      "<span style='color: #34d399;'>Default cache set to #{cache.display_name}.</span>"
    end

    def cache_abandon_command(identifier)
      return "<span style='color: #fbbf24;'>Usage: cache abandon &lt;address_or_nickname&gt;</span>" if identifier.blank?

      cache = resolve_own_cache(identifier)
      return "<span style='color: #f87171;'>Cache not found.</span>" unless cache
      return "<span style='color: #f87171;'>Cannot abandon your default cache. Set a different default first.</span>" if cache.is_default?
      return "<span style='color: #9ca3af;'>That cache is already abandoned.</span>" if cache.abandoned?

      cache.abandon!
      "<span style='color: #fbbf24;'>Cache #{cache.address} has been abandoned.</span>\n<span style='color: #9ca3af;'>It will persist on the ledger but can no longer send or receive CRED.</span>"
    end

    def cache_name_command(args)
      if args.length < 2
        return "<span style='color: #fbbf24;'>Usage: cache name &lt;address_or_nickname&gt; &lt;new_nickname&gt;</span>"
      end

      identifier = args[0]
      new_nickname = args[1]

      cache = resolve_own_cache(identifier)
      return "<span style='color: #f87171;'>Cache not found.</span>" unless cache

      cache.nickname = new_nickname
      if cache.save
        "<span style='color: #34d399;'>Cache #{cache.address} nicknamed '#{h(new_nickname)}'.</span>"
      else
        "<span style='color: #f87171;'>#{cache.errors.full_messages.join(", ")}</span>"
      end
    end

    # --- Chain commands ---

    def chain_command(args)
      subcmd = args.first&.downcase
      sub_args = args[1..] || []

      case subcmd
      when "latest"
        chain_latest_command
      when "tx"
        chain_tx_command(sub_args.first)
      when "cache"
        chain_cache_command(sub_args.first)
      when "supply"
        chain_supply_command
      when nil
        "<span style='color: #fbbf24;'>Usage: chain latest | chain tx &lt;hash&gt; | chain cache &lt;address&gt; | chain supply</span>"
      else
        "<span style='color: #f87171;'>Unknown chain command: #{h(subcmd)}. Try 'chain latest', 'chain tx', 'chain cache', or 'chain supply'.</span>"
      end
    end

    def chain_latest_command
      txs = GridTransaction.recent.limit(10).includes(:from_cache, :to_cache)
      return "<span style='color: #9ca3af;'>The ledger is empty.</span>" if txs.empty?

      lines = ["<span style='color: #22d3ee; font-weight: bold;'>GLOBAL LEDGER — LATEST TRANSACTIONS</span>", ""]
      txs.each do |tx|
        label, type_color = tx_type_display(tx.tx_type)
        memo_tag = tx.memo.present? ? " <span style='color: #6b7280;'>#{h(tx.memo)}</span>" : ""
        lines << "  <span style='color: #6b7280;'>[#{grid_time(tx.created_at)}]</span> <span style='color: #{type_color};'>[#{label}]</span> <span style='color: #9ca3af;'>#{tx.from_cache.address} → #{tx.to_cache.address}</span> <span style='color: #34d399;'>#{format_cred(tx.amount)} CRED</span>#{memo_tag}"
      end
      lines.join("\n")
    end

    def chain_tx_command(hash_fragment)
      return "<span style='color: #fbbf24;'>Usage: chain tx &lt;hash&gt;</span>" if hash_fragment.blank?

      tx = GridTransaction.find_by(tx_hash: hash_fragment)
      tx ||= GridTransaction.where("tx_hash LIKE ?", "#{hash_fragment}%").first

      return "<span style='color: #f87171;'>Transaction not found.</span>" unless tx

      lines = []
      lines << "<span style='color: #22d3ee; font-weight: bold;'>TRANSACTION DETAIL</span>"
      lines << ""
      lines << "  <span style='color: #fbbf24;'>Hash:</span>     <span style='color: #d0d0d0;'>#{tx.tx_hash}</span>"
      lines << "  <span style='color: #fbbf24;'>Prev:</span>     <span style='color: #6b7280;'>#{tx.previous_tx_hash || "GENESIS"}</span>"
      label, type_color = tx_type_display(tx.tx_type)
      lines << "  <span style='color: #fbbf24;'>Type:</span>     <span style='color: #{type_color};'>#{label}</span>"
      lines << "  <span style='color: #fbbf24;'>From:</span>     <span style='color: #9ca3af;'>#{tx.from_cache.address}</span>"
      lines << "  <span style='color: #fbbf24;'>To:</span>       <span style='color: #9ca3af;'>#{tx.to_cache.address}</span>"
      lines << "  <span style='color: #fbbf24;'>Amount:</span>   <span style='color: #34d399;'>#{format_cred(tx.amount)} CRED</span>"
      lines << "  <span style='color: #fbbf24;'>Memo:</span>     <span style='color: #d0d0d0;'>#{tx.memo.present? ? h(tx.memo) : "—"}</span>"
      lines << "  <span style='color: #fbbf24;'>Time:</span>     <span style='color: #6b7280;'>#{grid_time(tx.created_at, format: :long)}</span>"
      lines.join("\n")
    end

    def chain_cache_command(address)
      return "<span style='color: #fbbf24;'>Usage: chain cache &lt;address&gt;</span>" if address.blank?

      cache = GridCache.find_by("LOWER(address) = ?", address.downcase)
      return "<span style='color: #f87171;'>Cache not found.</span>" unless cache

      txs = GridTransaction.for_cache(cache).recent.limit(15).includes(:from_cache, :to_cache)

      lines = ["<span style='color: #22d3ee; font-weight: bold;'>LEDGER — #{cache.address}</span>"]
      lines << "<span style='color: #fbbf24;'>Balance:</span> <span style='color: #34d399;'>#{format_cred(cache.balance)} CRED</span>"
      lines << "<span style='color: #fbbf24;'>Status:</span> <span style='color: #d0d0d0;'>#{cache.status.upcase}</span>"
      lines << ""

      if txs.any?
        txs.each do |tx|
          direction = (tx.to_cache_id == cache.id) ? "+" : "-"
          color = (direction == "+") ? "#34d399" : "#f87171"
          other = (direction == "+") ? tx.from_cache.address : tx.to_cache.address
          memo_tag = tx.memo.present? ? " <span style='color: #6b7280;'>#{h(tx.memo)}</span>" : ""
          lines << "  <span style='color: #6b7280;'>[#{grid_time(tx.created_at)}]</span> <span style='color: #{color};'>#{direction}#{format_cred(tx.amount)}</span> <span style='color: #9ca3af;'>#{other}</span>#{memo_tag}"
        end
      else
        lines << "  <span style='color: #6b7280;'>No transactions.</span>"
      end
      lines.join("\n")
    end

    def chain_supply_command
      config = Grid::EconomyConfig
      halving = config.halving_factor
      mining_mined = config.mining_pool_mined
      gameplay_awarded = config.total_gameplay_awarded
      total_circulating = mining_mined + gameplay_awarded - config.total_burned - config.total_redeemed

      lines = []
      lines << "<span style='color: #22d3ee; font-weight: bold;'>CRED SUPPLY</span>"
      lines << ""
      lines << "  <span style='color: #fbbf24;'>Total Supply:</span>       <span style='color: #d0d0d0;'>#{format_cred(config::TOTAL_SUPPLY)} CRED</span>"
      lines << ""
      lines << "  <span style='color: #fbbf24;'>Mining Pool:</span>        <span style='color: #34d399;'>#{format_cred(config.mining_pool_balance)}</span> <span style='color: #6b7280;'>remaining of #{format_cred(config::MINING_POOL_TOTAL)}</span>"
      lines << "  <span style='color: #fbbf24;'>Fracture Reserve:</span>   <span style='color: #34d399;'>#{format_cred(config.gameplay_pool_balance)}</span> <span style='color: #6b7280;'>remaining of #{format_cred(config::GAMEPLAY_POOL_TOTAL)}</span>"
      lines << ""
      lines << "  <span style='color: #fbbf24;'>Total Mined:</span>        <span style='color: #d0d0d0;'>#{format_cred(mining_mined)}</span>"
      lines << "  <span style='color: #fbbf24;'>Total Burned:</span>       <span style='color: #d0d0d0;'>#{format_cred(config.total_burned)}</span>"
      lines << "  <span style='color: #fbbf24;'>Total Redeemed:</span>     <span style='color: #d0d0d0;'>#{format_cred(config.total_redeemed)}</span>"
      lines << "  <span style='color: #fbbf24;'>Circulating:</span>        <span style='color: #22d3ee;'>#{format_cred(total_circulating)}</span>"
      lines << ""
      lines << "  <span style='color: #fbbf24;'>Halving Factor:</span>     <span style='color: #d0d0d0;'>#{halving}x</span>"
      lines << "  <span style='color: #fbbf24;'>Mining Rate/Tick:</span>   <span style='color: #d0d0d0;'>#{halving} × base rate × rig multiplier</span>"
      lines.join("\n")
    end

    # --- Rig commands ---

    def rig_command(args)
      subcmd = args.first&.downcase
      sub_args = args[1..] || []

      rig = hackr.grid_mining_rig
      return "<span style='color: #f87171;'>You don't have a mining rig. This shouldn't happen!</span>" unless rig

      case subcmd
      when nil
        rig_status_command(rig)
      when "on"
        rig_on_command(rig)
      when "off"
        rig_off_command(rig)
      when "install"
        rig_install_command(rig, sub_args.join(" "))
      when "uninstall"
        rig_uninstall_command(rig, sub_args.join(" "))
      when "inspect"
        rig_inspect_command(rig)
      else
        "<span style='color: #f87171;'>Unknown rig command: #{h(subcmd)}. Try 'rig', 'rig on', 'rig off', 'rig install', 'rig uninstall', or 'rig inspect'.</span>"
      end
    end

    def rig_status_command(rig)
      status = rig.active? ? "<span style='color: #34d399;'>● ONLINE</span>" : "<span style='color: #f87171;'>○ OFFLINE</span>"
      functional = rig.functional?
      halving = Grid::EconomyConfig.halving_factor
      rate = (rig.effective_rate * halving).floor

      lines = []
      lines << "\n<span style='color: #a78bfa;'>════════════════════════════════════════</span>"
      lines << "<span style='color: #22d3ee; font-weight: bold;'>MINING RIG</span>"
      lines << "<span style='color: #a78bfa;'>════════════════════════════════════════</span>"
      lines << ""
      lines << "  <span style='color: #fbbf24;'>Status:</span>     #{status}#{" <span style='color: #f87171;'>[NON-FUNCTIONAL]</span>" unless functional}"
      lines << "  <span style='color: #fbbf24;'>Rate:</span>       <span style='color: #34d399;'>#{rate} CRED/tick</span> <span style='color: #6b7280;'>(base #{rig.effective_rate} × #{halving} halving)</span>"
      lines << "  <span style='color: #fbbf24;'>Boards:</span>     <span style='color: #d0d0d0;'>#{rig.motherboards.count} motherboard(s)</span>"
      lines << "  <span style='color: #fbbf24;'>Slots:</span>      <span style='color: #d0d0d0;'>PSU #{rig.psus.count}/#{rig.total_psu_slots} | CPU #{rig.cpus.count}/#{rig.total_cpu_slots} | GPU #{rig.gpus.count}/#{rig.total_gpu_slots} | RAM #{rig.rams.count}/#{rig.total_ram_slots}</span>"
      unless functional
        rig.functionality_errors.each do |err|
          lines << "  <span style='color: #f87171;'>⚠ #{h(err)}</span>"
        end
      end
      if rig.last_tick_at
        lines << "  <span style='color: #fbbf24;'>Last Tick:</span>  <span style='color: #6b7280;'>#{grid_time(rig.last_tick_at, format: :long)}</span>"
      end
      lines << "<span style='color: #a78bfa;'>════════════════════════════════════════</span>"
      lines.join("\n")
    end

    def rig_on_command(rig)
      return "<span style='color: #9ca3af;'>Your rig is already running.</span>" if rig.active?

      unless rig.functional?
        errors = rig.functionality_errors.map { |e| "  <span style='color: #f87171;'>⚠ #{h(e)}</span>" }.join("\n")
        return "<span style='color: #f87171;'>Rig is non-functional. Fix the following:</span>\n#{errors}"
      end

      rig.activate!
      "<span style='color: #34d399;'>Mining rig activated. ● ONLINE</span>\n<span style='color: #6b7280;'>You will begin earning CRED on the next mining tick.</span>"
    end

    def rig_off_command(rig)
      return "<span style='color: #9ca3af;'>Your rig is already offline.</span>" unless rig.active?

      rig.deactivate!
      "<span style='color: #fbbf24;'>Mining rig deactivated. ○ OFFLINE</span>\n<span style='color: #6b7280;'>Passive mining stopped. You can still earn CRED by watching live streams.</span>"
    end

    def rig_install_command(rig, item_name)
      return "<span style='color: #fbbf24;'>Install what? Usage: rig install &lt;item&gt;</span>" if item_name.blank?
      return "<span style='color: #f87171;'>Your rig must be powered down before modifying components. Use 'rig off' first.</span>" if rig.active?

      item = hackr.grid_items.where(grid_mining_rig_id: nil).find_by("LOWER(name) = ?", item_name.downcase)
      return "<span style='color: #f87171;'>You don't have '#{h(item_name)}' in your inventory.</span>" unless item
      return "<span style='color: #f87171;'>#{h(item.name)} is not a rig component.</span>" unless item.component?

      slot = item.slot
      return "<span style='color: #f87171;'>#{h(item.name)} has no slot defined.</span>" unless slot.present?

      # Slot capacity check
      unless rig.slot_available?(slot)
        case slot
        when "psu"
          return "<span style='color: #f87171;'>No PSU slot available. Each motherboard supports 1 PSU (#{rig.psus.count}/#{rig.total_psu_slots} installed).</span>"
        when "cpu"
          return "<span style='color: #f87171;'>No CPU slot available (#{rig.cpus.count}/#{rig.total_cpu_slots} installed). Install another motherboard for more slots.</span>"
        when "gpu"
          return "<span style='color: #f87171;'>No GPU slot available (#{rig.gpus.count}/#{rig.total_gpu_slots} installed). Install another motherboard for more slots.</span>"
        when "ram"
          return "<span style='color: #f87171;'>No RAM slot available (#{rig.rams.count}/#{rig.total_ram_slots} installed). Install another motherboard for more slots.</span>"
        else
          return "<span style='color: #f87171;'>No slot available for #{h(slot)}.</span>"
        end
      end

      item.update!(grid_mining_rig: rig, grid_hackr: nil, room: nil)

      rate_display = "×#{item.rate_multiplier}"
      "<span style='color: #34d399;'>Installed #{h(item.name)} into #{slot.upcase} slot.</span> <span style='color: #6b7280;'>(#{rate_display})</span>\n<span style='color: #9ca3af;'>Rig effective rate: #{rig.reload.effective_rate} CRED/tick (base)</span>"
    end

    def rig_uninstall_command(rig, item_name)
      return "<span style='color: #fbbf24;'>Uninstall what? Usage: rig uninstall &lt;component&gt;</span>" if item_name.blank?
      return "<span style='color: #f87171;'>Your rig must be powered down before modifying components. Use 'rig off' first.</span>" if rig.active?

      item = rig.components.find_by("LOWER(name) = ?", item_name.downcase)
      return "<span style='color: #f87171;'>No component named '#{h(item_name)}' is installed in your rig.</span>" unless item

      # Motherboard removal: check that remaining boards have capacity for installed components
      if item.slot == "motherboard"
        unless rig.can_remove_motherboard?(item)
          return "<span style='color: #f87171;'>Cannot remove this motherboard — installed components exceed remaining slot capacity. Uninstall components first.</span>"
        end
      end

      item.update!(grid_hackr: hackr, grid_mining_rig: nil, room: nil)
      rig.reload

      # Auto-deactivate if rig is no longer functional
      was_functional = rig.functional?
      output = "<span style='color: #34d399;'>Uninstalled #{h(item.name)} from your rig. It's now in your inventory.</span>"
      output += "\n<span style='color: #9ca3af;'>Rig effective rate: #{rig.effective_rate} CRED/tick (base)</span>"

      unless was_functional
        rig.functionality_errors.each do |err|
          output += "\n<span style='color: #f87171;'>⚠ #{h(err)}</span>"
        end
      end

      output
    end

    def rig_inspect_command(rig)
      status = rig.active? ? "<span style='color: #34d399;'>● ONLINE</span>" : "<span style='color: #f87171;'>○ OFFLINE</span>"
      functional = rig.functional?

      lines = []
      lines << "\n<span style='color: #a78bfa;'>════════════════════════════════════════════════════════</span>"
      non_functional_tag = functional ? nil : " <span style='color: #f87171;'>[NON-FUNCTIONAL]</span>"
      lines << "<span style='color: #22d3ee; font-weight: bold;'>RIG INSPECTION</span> #{status}#{non_functional_tag}"
      lines << "<span style='color: #a78bfa;'>════════════════════════════════════════════════════════</span>"

      if rig.motherboards.empty?
        lines << ""
        lines << "  <span style='color: #4b5563;'>No motherboard installed. Rig is non-functional.</span>"
      else
        rig.motherboards.each_with_index do |mb, i|
          color = mb.rarity_color
          name_display = mb.unicorn? ? mb.rainbow_name_html : "<span style='color: #{color};'>#{h(mb.name)}</span>"
          rarity_tag = mb.rarity ? " <span style='color: #{color};'>[#{mb.rarity_label}]</span>" : ""
          cpu_slots = (mb.properties&.dig("cpu_slots") || 1).to_i
          gpu_slots = (mb.properties&.dig("gpu_slots") || 2).to_i
          ram_slots = (mb.properties&.dig("ram_slots") || 2).to_i

          lines << ""
          lines << "  <span style='color: #22d3ee;'>BOARD #{i + 1}:</span> #{name_display}#{rarity_tag} <span style='color: #6b7280;'>(×#{mb.rate_multiplier})</span>"
          lines << "  <span style='color: #6b7280;'>         Slots: #{cpu_slots} CPU / #{gpu_slots} GPU / #{ram_slots} RAM / 1 PSU</span>"
        end
      end

      # List components by type with empty slot indicators
      {
        "PSU" => {items: rig.psus, total: rig.total_psu_slots},
        "CPU" => {items: rig.cpus, total: rig.total_cpu_slots},
        "GPU" => {items: rig.gpus, total: rig.total_gpu_slots},
        "RAM" => {items: rig.rams, total: rig.total_ram_slots}
      }.each do |label, data|
        lines << ""
        data[:items].each do |comp|
          color = comp.rarity_color
          name_display = comp.unicorn? ? comp.rainbow_name_html : "<span style='color: #{color};'>#{h(comp.name)}</span>"
          rarity_tag = comp.rarity ? " <span style='color: #{color};'>[#{comp.rarity_label}]</span>" : ""
          lines << "  <span style='color: #fbbf24;'>#{label.ljust(4)}</span> #{name_display}#{rarity_tag} <span style='color: #6b7280;'>(×#{comp.rate_multiplier})</span>"
        end
        empty = data[:total] - data[:items].size
        empty.times do
          lines << "  <span style='color: #fbbf24;'>#{label.ljust(4)}</span> <span style='color: #4b5563;'>[ empty ]</span>"
        end
        if data[:total].zero?
          lines << "  <span style='color: #fbbf24;'>#{label.ljust(4)}</span> <span style='color: #4b5563;'>[ no slots ]</span>"
        end
      end

      lines << ""
      lines << "  <span style='color: #fbbf24;'>Total Multiplier:</span> <span style='color: #22d3ee;'>×#{rig.total_multiplier}</span>"
      lines << "  <span style='color: #fbbf24;'>Effective Rate:</span>   <span style='color: #34d399;'>#{rig.effective_rate} CRED/tick (base)</span>"
      unless rig.functional?
        lines << ""
        rig.functionality_errors.each { |err| lines << "  <span style='color: #f87171;'>⚠ #{h(err)}</span>" }
      end
      lines << "<span style='color: #a78bfa;'>════════════════════════════════════════════════════════</span>"
      lines.join("\n")
    end

    # --- Economy helpers ---

    def grid_time(time, format: :short)
      future = time.change(year: time.year + 100)
      case format
      when :short then future.strftime("%Y-%m-%d %H:%M")
      when :long then future.strftime("%Y-%m-%d %H:%M:%S UTC")
      end
    end

    def tx_type_display(tx_type)
      case tx_type
      when "transfer" then ["TRANSFER", "#d0d0d0"]
      when "mining_reward" then ["MINING", "#34d399"]
      when "gameplay_reward" then ["FRACTURE RESERVE", "#fbbf24"]
      when "burn" then ["BURN", "#f87171"]
      when "redemption" then ["REDEMPTION", "#c084fc"]
      when "genesis" then ["GENESIS", "#22d3ee"]
      else [tx_type.upcase, "#9ca3af"]
      end
    end

    def resolve_own_cache(identifier)
      return nil if identifier.blank?
      # Try nickname first, then address
      hackr.grid_caches.find_by("LOWER(nickname) = ?", identifier.downcase) ||
        hackr.grid_caches.find_by("LOWER(address) = ?", identifier.downcase)
    end

    def resolve_any_cache(identifier)
      return nil if identifier.blank?
      # Try own nickname first, then any address
      hackr.grid_caches.find_by("LOWER(nickname) = ?", identifier.downcase) ||
        GridCache.find_by("LOWER(address) = ?", identifier.downcase)
    end

    def format_cred(amount)
      prefix = amount.negative? ? "-" : ""
      "#{prefix}#{amount.abs.to_s.reverse.scan(/\d{1,3}/).join(",").reverse}"
    end

    # --- Progression helpers ---

    def achievement_checker
      @achievement_checker ||= Grid::AchievementChecker.new(hackr)
    end

    def reputation_service
      @reputation_service ||= Grid::ReputationService.new(hackr)
    end

    def increment_stat!(key, amount = 1)
      current = hackr.stat(key) || 0
      hackr.set_stat!(key, current + amount)
    end

    def append_notifications(output, notifications)
      return output if notifications.empty?
      [output, *notifications].compact.join("\n")
    end

    # --- Reputation helpers ---

    # Apply rep and return a short inline notification for the command output,
    # or nil if the subject is missing/misconfigured or the delta clamped to zero.
    # Aggregate-faction misconfiguration (NPC/vendor assigned to a faction with
    # incoming rep-links) is swallowed silently — gameplay should never crash
    # because world data has a bad edge; it just skips the rep award.
    def grant_faction_rep(faction, delta, reason:, source: nil)
      return nil unless faction
      result = reputation_service.adjust!(faction, delta, reason: reason, source: source)
      return nil if result.nil? || result[:applied_delta].zero?
      build_rep_notification(result)
    rescue Grid::ReputationService::SubjectMissing,
      Grid::ReputationService::AggregateSubjectNotAdjustable
      nil
    end

    def build_rep_notification(result)
      subject = result[:subject]
      delta = result[:applied_delta]
      sign = delta.positive? ? "+" : ""
      delta_color = delta.positive? ? "#34d399" : "#ef4444"
      tier_transition = (result[:tier_before][:key] != result[:tier_after][:key])

      parts = [
        "<span style='color: #fbbf24;'>▲ REP</span>",
        "<span style='color: #{delta_color};'>#{sign}#{delta}</span>",
        "<span style='color: #9ca3af;'>::</span>",
        "<span style='color: #a78bfa;'>#{h(subject.display_name)}</span>",
        tier_label_span(result[:tier_after])
      ]
      lines = [parts.join(" ")]

      if tier_transition
        lines << "  <span style='color: #fbbf24;'>▲▲ #{h(subject.display_name)}: #{result[:tier_before][:label]} → #{result[:tier_after][:label]}</span>"
      end

      result[:rollups].each do |rollup|
        rollup_transition = rollup[:tier_before][:key] != rollup[:tier_after][:key]
        next unless rollup_transition
        lines << "  <span style='color: #a78bfa;'>▲ #{h(rollup[:faction].display_name)}: #{rollup[:tier_before][:label]} → #{rollup[:tier_after][:label]}</span>"
      end

      lines.join("\n")
    end

    # Longest tier label — used to pad the tier badge column so bars align.
    TIER_BADGE_WIDTH = Grid::Reputation::TIERS.map { |t| t[:label].length }.max + 2 # brackets
    # Widest numeric value: sign + up to 4 digits = 5 chars (e.g. "+1000", "-1000").
    REP_VALUE_WIDTH = 5

    def tier_label_span(tier, pad_to: TIER_BADGE_WIDTH)
      padded = "[#{tier[:label]}]".ljust(pad_to)
      "<span style='color: #{tier[:color]};'>#{padded}</span>"
    end

    # Render a single standing line.
    # `compact: true` → short form for the `stat` STANDING block (no bar, no next-tier).
    # `compact: false` → full form for `rep` (bar, next-tier hint, rollup contribution footnote).
    def format_rep_row(standing, name_width:, depth: 0, compact: false)
      faction = standing[:faction]
      tier = standing[:tier]
      effective = standing[:effective]
      # depth 0 → no prefix; depth 1 → "└─ "; each deeper level adds 2 leading
      # spaces so grandchildren stack visibly under their parent's "└─".
      indent = (depth > 0) ? ("  " * (depth - 1)) + "└─ " : ""
      label_padded = "#{indent}#{faction.display_name}".ljust(name_width)
      value_padded = format_rep_value(effective).rjust(REP_VALUE_WIDTH)

      if compact
        tag = standing[:aggregate] ? " <span style='color: #6b7280;'>(rollup)</span>" : ""
        return "<span style='color: #d0d0d0;'>#{h(label_padded)}</span>  #{tier_label_span(tier)} <span style='color: #9ca3af;'>#{value_padded}</span>#{tag}"
      end

      bar = rep_bar(effective)
      next_tier_str = if standing[:next_tier]
        diff = standing[:next_tier][:min] - effective
        "<span style='color: #6b7280;'>#{diff} to #{standing[:next_tier][:label]}</span>"
      else
        "<span style='color: #fbbf24;'>[MAX]</span>"
      end

      "  <span style='color: #d0d0d0;'>#{h(label_padded)}</span>  #{tier_label_span(tier)}  #{bar}  <span style='color: #9ca3af;'>#{value_padded}</span>  #{next_tier_str}"
    end

    # 20-cell bar spanning -1000..+1000, centered on zero. Color reflects tier.
    def rep_bar(value)
      width = 20
      half = width / 2
      clamped = value.clamp(Grid::Reputation::MIN_VALUE, Grid::Reputation::MAX_VALUE)
      fill_cells = (clamped.abs * half / Grid::Reputation::MAX_VALUE.to_f).round
      tier = Grid::Reputation.tier_for(value)

      left = if value < 0
        ("░" * (half - fill_cells)) + ("█" * fill_cells)
      else
        "░" * half
      end
      right = if value > 0
        ("█" * fill_cells) + ("░" * (half - fill_cells))
      else
        "░" * half
      end
      "<span style='color: #{tier[:color]};'>#{left}│#{right}</span>"
    end

    def format_rep_value(value)
      sign = value.positive? ? "+" : ""
      "#{sign}#{value}"
    end

    def slugify(text)
      text.to_s.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/^_|_$/, "")
    end
  end
end
