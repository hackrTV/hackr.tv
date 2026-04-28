module Grid
  class CommandParser
    include CodexHelper
    include ItemEffectApplier

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

      # BREACH mode: all input routes through BreachCommandParser
      if (active_breach = hackr.active_breach)
        return Grid::BreachCommandParser.new(hackr, input, active_breach).execute
      end

      # Captured mode: restricted command set in GovCorp facility
      if Grid::ContainmentService.captured?(hackr)
        return Grid::CapturedCommandParser.new(hackr, input, self).execute
      end

      # Split input but preserve case in arguments
      parts = input.split
      command = parts.first&.downcase
      args = parts[1..]

      result = dispatch_command(command, args)

      # Normalize result to hash format
      result.is_a?(Hash) ? result : {output: result, event: nil}
    end

    # Extracted for delegation by CapturedCommandParser.
    # Accepts pre-parsed command + args and returns raw result.
    def dispatch_command(command, args)
      case command
      when "look", "l"
        look_command
      when "go", "move"
        go_command(args&.first)
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
        say_command(args&.join(" "))
      when "inventory", "inv", "i"
        inventory_command
      when "take", "get"
        take_command(args&.join(" "))
      when "drop"
        drop_command(args&.join(" "))
      when "examine", "ex", "x"
        examine_command(args&.join(" "))
      when "talk"
        talk_command(args&.join(" "))
      when "ask"
        ask_command(args)
      when "stat", "stats", "st"
        stat_command
      when "rep", "reputation", "standing"
        rep_command
      when "use"
        use_command(args&.join(" "))
      when "salvage", "sal"
        salvage_command(args&.join(" "))
      when "analyze", "an"
        analyze_command(args&.join(" "))
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
        buy_command(args&.join(" "))
      when "sell"
        sell_command(args&.join(" "))
      when "missions", "quests"
        missions_command
      when "mission", "quest"
        mission_detail_command(args&.first)
      when "accept", "acc", "ac"
        accept_mission_command(args&.first)
      when "abandon"
        abandon_mission_command(args&.first)
      when "turn_in", "turnin", "ti"
        turn_in_command(args&.first)
      when "give"
        give_command(args)
      when "fabricate", "fab"
        fabricate_command(args&.first)
      when "schematics", "schem", "sch"
        args&.any? ? schematic_detail_command(args.first) : schematics_command
      when "schematic"
        schematic_detail_command(args&.first)
      when "place", "install"
        place_fixture_command(args&.join(" "))
      when "unplace", "uninstall"
        unplace_fixture_command(args&.join(" "))
      when "store", "put"
        store_in_fixture_command(args)
      when "retrieve"
        retrieve_from_fixture_command(args)
      when "peek", "search"
        peek_fixture_command(args&.join(" "))
      when "equip", "wear"
        equip_command(args&.join(" "))
      when "unequip", "remove"
        unequip_command(args&.join(" "))
      when "loadout", "lo"
        loadout_command
      when "deck", "dk"
        args&.empty? ? deck_show_command : deck_subcommand(args)
      when "breach", "br"
        breach_initiate_command(args&.join(" "))
      when "repair"
        repair_command
      when "den"
        den_command(args)
      when "out"
        go_command("out")
      when "home"
        go_command("home")
      when "help", "?"
        help_command
      when "who"
        who_command
      when "clear", "cls", "cl"
        clear_command
      else
        "<span style='color: #f87171;'>Unknown command: #{h(command)}. Type 'help' for a list of commands.</span>"
      end
    end

    private

    def look_command
      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere. This shouldn't happen!</span>" unless room

      output = []
      output << "\n<span style='color: #a78bfa;'>════════════════════════════════════════════════════════════════</span>"
      output << "<span style='color: #22d3ee; font-weight: bold;'>#{room.name.upcase}</span> <span style='color: #666;'>::</span> <span style='color: #fbbf24;'>#{room.grid_zone.name}</span> <span style='color: #666;'>::</span> <span style='color: #a78bfa;'>#{room.grid_zone.grid_region&.name || "Unknown Region"}</span>"
      output << "<span style='color: #9ca3af;'>[#{room.color_scheme}]</span>" if room.color_scheme
      output << ""
      output << "<span style='color: #d0d0d0;'>#{codex_linkify(room.description)}</span>" if room.description

      # Den banner
      if room.den?
        output << ""
        if room.owner_id == hackr.id
          output << "<span style='color: #22d3ee; font-weight: bold;'>[ THIS IS YOUR DEN ]</span>"
        else
          owner_alias = room.owner&.hackr_alias || "Unknown"
          output << "<span style='color: #a78bfa;'>[ This is #{h(owner_alias)}'s Den ]</span>"
        end
        output << "<span style='color: #6b7280;'>Floor: #{room.den_floor_count}/#{Grid::DenService::DEN_STORAGE_CAP} items</span>"
        output << "<span style='color: #6b7280;'>Owner: <span style='color: #a78bfa;'>#{h(room.owner&.hackr_alias)}</span></span>"
        output << "<span style='color: #f87171;'>[ DEN IS LOCKED ]</span>" if room.locked?
      end

      # Breach target indicator(s)
      breach_encounters = Grid::BreachService.available_encounters(room: room, hackr: hackr)
      if breach_encounters.any?
        output << ""
        if breach_encounters.size == 1
          enc = breach_encounters.first
          output << "<span style='color: #22d3ee; font-weight: bold;'>[ BREACH TARGET DETECTED ]</span> <span style='color: #9ca3af;'>#{h(enc.name)} :: #{enc.tier_label}</span>"
          output << "<span style='color: #6b7280;'>  Type 'breach' to initiate.</span>"
        else
          output << "<span style='color: #22d3ee; font-weight: bold;'>[ BREACH TARGETS DETECTED ]</span>"
          breach_encounters.each_with_index do |enc, i|
            output << "<span style='color: #9ca3af;'>  [#{i + 1}] #{h(enc.name)} :: #{enc.tier_label}</span>"
          end
          output << "<span style='color: #6b7280;'>  Type 'breach &lt;name or #&gt;' to initiate.</span>"
        end
      end

      output << ""

      # Show exits
      exits = room.exits_from.includes(to_room: :owner)
      if room.slug == Grid::DenService::RESIDENTIAL_CORRIDOR_SLUG
        # In corridor: split standard exits from den exits
        # Batch-load accessible den IDs to avoid N+1 on can_enter_den?
        accessible_den_ids = accessible_den_room_ids
        std_exits = exits.reject { |e| e.to_room.den? }
        den_exits = exits.select { |e| e.to_room.den? && accessible_den_ids.include?(e.to_room.id) }

        if std_exits.any?
          exit_list = std_exits.map { |e| "<span style='color: #22d3ee;'>#{e.direction}</span> <span style='color: #9ca3af;'>(#{e.to_room.name})</span>" }.join(", ")
          output << "<span style='color: #fbbf24;'>Exits:</span> #{exit_list}"
        else
          output << "<span style='color: #fbbf24;'>Exits:</span> <span style='color: #6b7280;'>none</span>"
        end

        if den_exits.any?
          output << ""
          output << "<span style='color: #fbbf24;'>Private Dens:</span>"
          den_exits.each do |e|
            den = e.to_room
            owner_tag = (den.owner_id == hackr.id) ? " <span style='color: #22d3ee;'>[YOUR DEN]</span>" : ""
            lock_tag = den.locked? ? " <span style='color: #f87171;'>[LOCKED]</span>" : ""
            output << "  <span style='color: #22d3ee;'>go #{e.direction}</span> <span style='color: #9ca3af;'>→ #{h(den.name)}</span>#{owner_tag}#{lock_tag}"
          end
        end
      elsif exits.any?
        exit_list = exits.map { |e| "<span style='color: #22d3ee;'>#{e.direction}</span> <span style='color: #9ca3af;'>(#{e.to_room.name})</span>" }.join(", ")
        output << "<span style='color: #fbbf24;'>Exits:</span> #{exit_list}"
      else
        output << "<span style='color: #fbbf24;'>Exits:</span> <span style='color: #6b7280;'>none</span>"
      end

      # Show fixtures (den only)
      if room.den?
        fixtures = room.placed_fixtures.includes(:stored_items)
        if fixtures.any?
          output << ""
          output << "<span style='color: #fbbf24;'>Fixtures:</span>"
          fixtures.each do |f|
            used = f.stored_items.size
            cap = f.storage_capacity
            output << "  <span style='color: #a78bfa;'>#{h(f.name)}</span> <span style='color: #6b7280;'>[#{used}/#{cap} slots]</span>"
          end
        end
      end

      # Show items (floor items, excluding placed fixtures)
      floor_items = room.den? ? room.den_floor_items : room.grid_items.in_room(room)
      if floor_items.any?
        output << ""
        item_names = floor_items.map { |item| item.unicorn? ? item.rainbow_name_html : "<span style='color: #34d399;'>#{h(item.name)}</span>" }
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
        hackr_entries = other_hackrs.map do |other|
          visible = other.grid_items.equipped_by(other).where(equipped_slot: GridItem::VISIBLE_SLOTS)
          gear_tag = if visible.any?
            items = visible.map { |gi| "<span style='color: #{gi.rarity_color};'>#{h(gi.name)}</span>" }
            " <span style='color: #6b7280;'>[#{items.join(", ")}]</span>"
          else
            ""
          end
          "<span style='color: #a78bfa;'>#{h(other.hackr_alias)}</span>#{gear_tag}"
        end
        output << "<span style='color: #fbbf24;'>Hackrs:</span> #{hackr_entries.join(", ")}"
      end

      # Facility alert HUD (captured mode)
      if Grid::ContainmentService.captured?(hackr)
        output << ""
        output << Grid::ContainmentService.render_alert_bar(hackr.stat("facility_alert_level").to_i)
      end

      output.join("\n")
    end

    def go_command(direction)
      return "<span style='color: #fbbf24;'>Go where? Specify a direction (e.g. north, south, east, west, up, down)</span>" unless direction

      old_room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless old_room

      # Zone lockout check — deny entry into locked-out zones
      if direction != "home" && direction != "den"
        exit_check = old_room.exits_from.includes(to_room: :grid_zone).find_by(direction: direction)
        if exit_check
          target_zone = exit_check.to_room.grid_zone
          lockout_until = hackr.stat("zone_lockout_#{target_zone.id}").to_i
          if lockout_until > 0 && Time.current.to_i < lockout_until
            remaining = ((lockout_until - Time.current.to_i) / 60.0).ceil
            return "<span style='color: #f87171;'>Zone lockout active for #{target_zone.name}. #{remaining} minute(s) remaining.</span>"
          end
        end
      end

      # "go home" / "go den" resolves to hackr's den slug when in the corridor
      if direction == "home" || direction == "den"
        den = GridRoom.where(owner: hackr).order(:id).first
        unless den
          return "<span style='color: #f87171;'>You don't have a den.</span>"
        end
        unless old_room.slug == Grid::DenService::RESIDENTIAL_CORRIDOR_SLUG
          return "<span style='color: #f87171;'>You must be in the Residential Corridor to enter your den.</span>"
        end
        direction = den.slug
      end

      exit = old_room.exits_from.find_by(direction: direction)

      # Prefix match for den slugs in the corridor (e.g. "go den-xeraen" matches "den-xeraen-a7f")
      if !exit && old_room.slug == Grid::DenService::RESIDENTIAL_CORRIDOR_SLUG && direction.start_with?("den-")
        matching_exits = old_room.exits_from.includes(:to_room)
          .where("direction LIKE ?", "#{ActiveRecord::Base.sanitize_sql_like(direction)}%")
          .select { |e| e.to_room.den? && accessible_den_room_ids.include?(e.to_room.id) }
        exit = matching_exits.first
      end

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

      # Den entry access control
      if new_room.den?
        if old_room.slug != Grid::DenService::RESIDENTIAL_CORRIDOR_SLUG
          return "<span style='color: #f87171;'>You must be in the Residential Corridor to enter a den.</span>"
        end
        if new_room.locked?
          return "<span style='color: #f87171;'>That den is locked from the inside.</span>"
        end
        unless den_service.can_enter_den?(new_room)
          return "<span style='color: #f87171;'>ACCESS DENIED. You have not been invited to this den.</span>"
        end
      end

      # Den exit — locked check
      if old_room.den? && old_room.locked?
        return "<span style='color: #f87171;'>The den is locked. Use 'den unlock' first.</span>"
      end

      # Track zone entry room for BREACH ejection
      if old_room.grid_zone_id != new_room.grid_zone_id
        hackr.update!(current_room: new_room, zone_entry_room_id: old_room.id)
      else
        hackr.update!(current_room: new_room)
      end

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
      notifications += mission_progressor.record(:visit_room, room_slug: new_room.slug)
      # Clearance may have changed if level-up happened above; check missions
      # that track reach_clearance too (cheap — progressor no-ops if none exist).
      notifications += mission_progressor.record(:reach_clearance, clearance: hackr.stat("clearance").to_i)
      look_output = append_notifications(look_output, notifications)

      # Facility alert check (captured mode) — increments alert on each move,
      # returns to containment cell if threshold reached
      if Grid::ContainmentService.captured?(hackr)
        alert_result = Grid::ContainmentService.alert_increment!(hackr: hackr)
        if alert_result.caught
          hackr.reload
          return {output: alert_result.display + "\n" + look_command, event: nil}
        elsif alert_result.display
          look_output += "\n" + alert_result.display
        end
      end

      # Ambient encounter check — random BREACH trigger based on zone danger_level
      ambient_result = Grid::BreachGeneratorService.ambient_check!(hackr: hackr, room: new_room)
      if ambient_result
        look_output += "\n" + ambient_result.display
        if ambient_result.ejected
          hackr.reload
          look_output += "\n" + look_command
        end
      end

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
      items = hackr.grid_items.in_inventory(hackr)
      cap = hackr.inventory_capacity
      used = items.count

      header_color = (used >= cap) ? "#f87171" : "#9ca3af"
      slot_display = "<span style='color: #{header_color};'>[#{used}/#{cap} slots]</span>"

      unless items.any?
        return "<span style='color: #fbbf24;'>Inventory:</span> #{slot_display}\n<span style='color: #9ca3af;'>Your inventory is empty.</span>"
      end

      lines = ["<span style='color: #fbbf24;'>Inventory:</span> #{slot_display}"]
      items.each do |item|
        color = item.rarity_color
        name_display = item.unicorn? ? item.rainbow_name_html : "<span style='color: #{color};'>#{h(item.name)}</span>"
        rarity_tag = item.rarity ? " <span style='color: #{color};'>[#{item.rarity_label}]</span>" : ""
        qty_tag = (item.quantity > 1) ? " <span style='color: #6b7280;'>x#{item.quantity}</span>" : ""
        stack_tag = if item.grid_item_definition&.max_stack && item.quantity > 1
          " <span style='color: #4b5563;'>(#{item.quantity}/#{item.grid_item_definition.max_stack})</span>"
        else
          ""
        end
        lines << "  - #{name_display}#{rarity_tag}#{qty_tag}#{stack_tag}"
      end
      lines.join("\n")
    end

    def take_command(item_name)
      parsed = Grid::QuantityParser.parse(item_name)
      item_name = parsed.remainder
      return "<span style='color: #fbbf24;'>Take what?</span>" if item_name.empty?

      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless room

      item = room.grid_items.in_room(room).find_by("LOWER(name) = ?", item_name.downcase)
      return "<span style='color: #f87171;'>You don't see '#{h(item_name)}' here.</span>" unless item

      # Den owner-only take restriction
      if room.den? && room.owner_id != hackr.id
        return "<span style='color: #f87171;'>You can't take items from someone else's den.</span>"
      end

      # Placed fixture with contents cannot be picked up
      if item.fixture? && item.placed? && item.stored_items.exists?
        return "<span style='color: #f87171;'>#{h(item.name)} has items stored inside. Retrieve them first.</span>"
      end

      saved_name = item.name
      saved_unicorn = item.unicorn?
      saved_rarity = item.rarity
      qty = nil

      ActiveRecord::Base.transaction do
        qty = Grid::ItemTransfer.move!(
          source_item: item,
          quantity: parsed.quantity,
          destination_type: :inventory,
          destination: hackr
        )
      end

      increment_stat!("items_taken", qty)

      qty_label = (qty > 1) ? " ×#{qty}" : ""
      name_display = saved_unicorn ? "<span class='rarity-unicorn'>#{h(saved_name)}</span>" : "<span style='color: #34d399;'>#{h(saved_name)}</span>"
      output = "<span style='color: #34d399;'>You take </span>#{name_display}<span style='color: #34d399;'>#{h(qty_label)}.</span>"
      notifications = achievement_checker.check(:take_item, item_name: saved_name)
      notifications += achievement_checker.check(:items_collected)
      notifications += achievement_checker.check(:rarity_owned, rarity: saved_rarity) if saved_rarity.present?
      notifications += mission_progressor.record(:collect_item, item_name: saved_name, amount: qty)
      output = append_notifications(output, notifications)

      {
        output: output,
        event: {
          type: "take",
          hackr_alias: hackr.hackr_alias,
          item_name: saved_name,
          room_id: room.id
        }
      }
    rescue Grid::InventoryErrors::InventoryFull => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue Grid::ItemTransfer::InsufficientQuantity => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    end

    def drop_command(item_name)
      parsed = Grid::QuantityParser.parse(item_name)
      item_name = parsed.remainder
      return "<span style='color: #fbbf24;'>Drop what?</span>" if item_name.empty?

      item = hackr.grid_items.in_inventory(hackr).find_by("LOWER(name) = ?", item_name.downcase)
      return equipped_item_hint(item_name) || "<span style='color: #f87171;'>You don't have '#{h(item_name)}'.</span>" unless item

      # Fixtures must be placed via the place command
      if item.fixture?
        return "<span style='color: #f87171;'>Use 'place #{h(item.name.downcase)}' to install fixtures in your den.</span>"
      end

      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless room

      # Den visitor restrictions
      if room.den? && room.owner_id != hackr.id
        return "<span style='color: #f87171;'>You can't drop items in someone else's den.</span>"
      end

      saved_name = item.name
      saved_unicorn = item.unicorn?
      qty = nil

      ActiveRecord::Base.transaction do
        qty = Grid::ItemTransfer.move!(
          source_item: item,
          quantity: parsed.quantity,
          destination_type: :room,
          destination: room
        )
      end

      notifications = []
      if room.den? && room.owner_id == hackr.id
        notifications += achievement_checker.check(:items_stored)
      end

      qty_label = (qty > 1) ? " ×#{qty}" : ""
      name_display = saved_unicorn ? "<span class='rarity-unicorn'>#{h(saved_name)}</span>" : "<span style='color: #34d399;'>#{h(saved_name)}</span>"
      output = "<span style='color: #34d399;'>You drop </span>#{name_display}<span style='color: #34d399;'>#{h(qty_label)}.</span>"
      output = append_notifications(output, notifications) if notifications.any?

      {
        output: output,
        event: {
          type: "drop",
          hackr_alias: hackr.hackr_alias,
          item_name: saved_name,
          room_id: room.id
        }
      }
    rescue Grid::ItemTransfer::DestinationFull => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue Grid::ItemTransfer::InsufficientQuantity => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
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
        listing = vendor.grid_shop_listings.includes(:grid_item_definition).joins(:grid_item_definition)
          .where(active: true)
          .where("min_clearance <= ?", clearance)
          .where("LOWER(grid_item_definitions.name) = ?", target.downcase)
          .first
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

      # Check for reset aliases at the end: "talk to Codec again"
      words = npc_name.split
      reset = false
      if words.length > 1 && DialogueNavigator.reset_alias?(words.last)
        reset = true
        npc_name = words[0..-2].join(" ")
      end

      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless room

      mob = room.grid_mobs.find_by("LOWER(name) = ?", npc_name.downcase)
      return "<span style='color: #f87171;'>You don't see '#{h(npc_name)}' here.</span>" unless mob
      return "<span style='color: #9ca3af;'>#{h(mob.name)} doesn't seem interested in talking.</span>" if mob.dialogue_tree.blank?

      nav = DialogueNavigator.new(hackr: hackr, mob: mob)
      nav.reset! if reset

      output = render_dialogue_position(mob, nav)

      increment_stat!("npcs_talked")

      rep_notif = grant_faction_rep(mob.grid_faction, 1, reason: "talk:#{slugify(mob.name)}", source: mob)
      notifications = achievement_checker.check(:talk_npc, npc_name: mob.name)
      notifications.unshift(rep_notif) if rep_notif
      notifications += mission_progressor.record(:talk_npc, npc_name: mob.name)
      # Rep changed from the talk grant — fire reach_rep for this faction.
      if mob.grid_faction
        notifications += mission_progressor.record(
          :reach_rep,
          faction_slug: mob.grid_faction.slug,
          rep_value: reputation_service.effective_rep(mob.grid_faction)
        )
      end
      append_notifications(output, notifications)
    end

    def ask_command(args)
      # Parse "ask <npc> about <topic>"
      return "<span style='color: #fbbf24;'>Ask whom about what? Usage: ask &lt;npc&gt; about &lt;topic&gt;</span>" if args.length < 2

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

      nav = DialogueNavigator.new(hackr: hackr, mob: mob)

      # Back navigation — render position without stats/rep
      if DialogueNavigator.back_alias?(topic)
        if nav.at_root?
          return dialogue_box("<span style='color: #9ca3af;'>You're already at the start of the conversation.</span>")
        end
        nav.go_back
        return render_dialogue_position(mob, nav)
      end

      # Mission intercepts — checked BEFORE topic dictionary lookup so a
      # quest_giver's topic list doesn't need to enumerate every mission
      # slug or the literal "missions"/"work" keyword.
      mission_topic = mission_topic_response(mob, topic, room)
      return dialogue_box(mission_topic) if mission_topic

      # Navigate the dialogue tree at current depth
      result = nav.navigate(topic)

      if result
        content = []
        content << "<span style='color: #c084fc;'>#{h(mob.name)}</span>: <span style='color: #60a5fa;'>\"#{h(result[:response])}\"</span>"

        append_topic_list(content, result[:topics])
        dialogue_box(content.join("\n"))
      else
        available_topics = nav.current_topics
        available = available_topics.keys.map { |k| h(k) }.join(", ")
        content = "<span style='color: #c084fc;'>#{h(mob.name)}</span> doesn't know about '#{h(topic)}'. <span style='color: #9ca3af;'>Try asking about:</span> <span style='color: #fbbf24;'>#{available}</span>"
        dialogue_box(content)
      end
    end

    # Returns HTML content (without dialogue_box wrapping) when `topic`
    # is a mission-related keyword or a specific mission slug offered by
    # this NPC. Nil otherwise — caller falls through to generic topics.
    def mission_topic_response(mob, topic, room)
      normalized = topic.to_s.downcase.strip
      return missions_offered_by_response(mob, room) if %w[missions quests work assignments].include?(normalized)

      # Specific mission slug lookup. Case-insensitive. Match only missions
      # this NPC actually gives. Dialogue-path gate applies here too —
      # guessing the slug shouldn't bypass the depth requirement.
      mission = GridMission.published.find_by(
        "LOWER(slug) = ? AND giver_mob_id = ?", normalized, mob.id
      )
      if mission
        return nil if dialogue_path_blocked?(mission, mob)
        return mission_brief_response(mob, mission, room)
      end

      nil
    end

    def missions_offered_by_response(mob, room)
      current_path = hackr.dialogue_path_for(mob)
      available = mission_service.available_missions(room).select do |m|
        next false unless m.giver_mob_id == mob.id
        # Filter by dialogue_path gate: mission only visible if hackr has
        # navigated to (or past) the required dialogue depth.
        required = m.dialogue_path
        next true if required.blank?
        required.is_a?(Array) && required.length <= current_path.length &&
          current_path.first(required.length) == required
      end
      if available.empty?
        return "<span style='color: #c084fc;'>#{h(mob.name)}</span>: " \
          "<span style='color: #60a5fa;'>\"Nothing for you right now.\"</span>"
      end

      lines = ["<span style='color: #c084fc;'>#{h(mob.name)}</span>: " \
        "<span style='color: #60a5fa;'>\"Here's what I've got.\"</span>"]
      lines << ""
      available.each do |m|
        arc = m.grid_mission_arc ? " <span style='color: #6b7280;'>[#{h(m.grid_mission_arc.name)}]</span>" : ""
        rep_tag = m.repeatable? ? " <span style='color: #34d399;'>(repeatable)</span>" : ""
        lines << "  <span style='color: #fbbf24;'>#{h(m.slug)}</span>#{rep_tag} " \
          "<span style='color: #9ca3af;'>::</span> <span style='color: #d0d0d0;'>#{h(m.name)}</span>#{arc}"
        lines << "    <span style='color: #6b7280;'>#{h(m.description.to_s.truncate(120))}</span>" if m.description.present?
      end
      lines << ""
      lines << "<span style='color: #9ca3af;'>Use 'ask #{h(mob.name)} about &lt;slug&gt;' for details, or 'accept &lt;slug&gt;' to take the job.</span>"
      lines.join("\n")
    end

    def mission_brief_response(mob, mission, room)
      lines = []
      arc = mission.grid_mission_arc ? " <span style='color: #6b7280;'>[#{h(mission.grid_mission_arc.name)}]</span>" : ""
      # Giver may be nil — schema allows it and the loader leaves the FK
      # null if the YAML `giver_mob_name` can't be resolved. Render a
      # neutral header rather than dereferencing nil.
      speaker = mob ? "<span style='color: #c084fc;'>#{h(mob.name)}</span>: " : ""
      lines << "#{speaker}<span style='color: #22d3ee; font-weight: bold;'>#{h(mission.name)}</span>#{arc}"
      lines << "<span style='color: #d0d0d0;'>#{h(mission.description)}</span>" if mission.description.present?

      lines << ""
      lines << "<span style='color: #fbbf24;'>Objectives:</span>"
      mission.grid_mission_objectives.each do |obj|
        lines << "  <span style='color: #9ca3af;'>▸</span> #{h(obj.label)}" + ((obj.target_count > 1) ? " <span style='color: #6b7280;'>(×#{obj.target_count})</span>" : "")
      end

      rewards_summary = mission_rewards_summary(mission)
      if rewards_summary.present?
        lines << ""
        lines << "<span style='color: #fbbf24;'>Rewards:</span> #{rewards_summary}"
      end

      status_hint = mission_status_hint(mission, room)
      lines << ""
      lines << status_hint if status_hint
      lines.join("\n")
    end

    def mission_rewards_summary(mission)
      parts = []
      mission.grid_mission_rewards.each do |r|
        case r.reward_type
        when "xp"
          parts << "<span style='color: #34d399;'>+#{r.amount} XP</span>" if r.amount.to_i.positive?
        when "cred"
          parts << "<span style='color: #fbbf24;'>+#{r.amount} CRED</span>" if r.amount.to_i.positive?
        when "faction_rep"
          sign = (r.amount.to_i >= 0) ? "+" : ""
          color = (r.amount.to_i >= 0) ? "#34d399" : "#ef4444"
          parts << "<span style='color: #{color};'>#{sign}#{r.amount} rep</span> <span style='color: #9ca3af;'>(#{h(r.target_slug.to_s)})</span>" if r.amount.to_i != 0
        when "item_grant"
          qty_tag = (r.quantity.to_i > 1) ? " x#{r.quantity}" : ""
          parts << "<span style='color: #22d3ee;'>+ #{h(r.target_slug.to_s)}#{qty_tag}</span>"
        when "grant_achievement"
          parts << "<span style='color: #fbbf24;'>◆ Achievement</span>"
        end
      end
      parts.join(" <span style='color: #4b5563;'>|</span> ")
    end

    def mission_status_hint(mission, room)
      active = hackr.grid_hackr_missions.active.where(grid_mission_id: mission.id).exists?
      return "<span style='color: #fbbf24;'>You're already working on this. Use 'mission #{h(mission.slug)}' to see progress.</span>" if active

      completed_count = hackr.grid_hackr_missions.completed.where(grid_mission_id: mission.id).sum(:turn_in_count)
      if completed_count.positive? && !mission.repeatable?
        return "<span style='color: #9ca3af;'>You've already completed this job.</span>"
      end

      reason = refusal_reason(mission, room)
      if reason
        "<span style='color: #f87171;'>#{reason}</span>"
      else
        "<span style='color: #34d399;'>Available. Use 'accept #{h(mission.slug)}' to take this job.</span>"
      end
    end

    def refusal_reason(mission, room)
      unless room && mission.giver_mob_id && room.grid_mobs.exists?(id: mission.giver_mob_id)
        return "You need to speak to the giver in person to accept."
      end
      status = mission_service.gate_status(mission)
      status.reason ? h(status.reason) : nil
    end

    def help_command
      <<~HELP
        <span style='color: #22d3ee; font-weight: bold;'>Available Commands:</span>

        <span style='color: #fbbf24;'>Navigation:</span>
          <span style='color: #34d399;'>look, l</span>                    - Look around the room
          <span style='color: #34d399;'>go &lt;direction&gt;</span>             - Move in a direction
          <span style='color: #34d399;'>north, n / south, s</span>        - Move north/south
          <span style='color: #34d399;'>east, e / west, w</span>          - Move east/west
          <span style='color: #34d399;'>up, u / down, d</span>            - Move up/down

        <span style='color: #fbbf24;'>Items:</span>
          <span style='color: #34d399;'>inventory, inv, i</span>          - View your inventory
          <span style='color: #34d399;'>take [qty|all] &lt;item&gt;</span>     - Pick up item(s) from the room
          <span style='color: #34d399;'>drop [qty|all] &lt;item&gt;</span>     - Drop item(s) from inventory
          <span style='color: #34d399;'>use &lt;item&gt;</span>                 - Use an item
          <span style='color: #34d399;'>salvage [qty|all] &lt;item&gt;</span>  - Break down item(s) for XP
          <span style='color: #34d399;'>analyze &lt;item&gt;, an</span>         - Preview salvage yields before breaking down
          <span style='color: #34d399;'>examine &lt;target&gt;, x</span>        - Examine item, NPC, or hackr

        <span style='color: #fbbf24;'>Loadout:</span>
          <span style='color: #34d399;'>equip &lt;item&gt;, wear</span>         - Equip a gear item
          <span style='color: #34d399;'>unequip &lt;item|slot&gt;, remove</span> - Remove equipped gear
          <span style='color: #34d399;'>loadout, lo</span>                - View your current loadout

        <span style='color: #fbbf24;'>DECK &amp; BREACH:</span>
          <span style='color: #34d399;'>deck, dk</span>                   - View equipped DECK status
          <span style='color: #34d399;'>deck load &lt;software&gt;</span>       - Load software into DECK
          <span style='color: #34d399;'>deck unload &lt;software&gt;</span>     - Unload software from DECK
          <span style='color: #34d399;'>deck charge</span>                - Recharge DECK battery (at den)
          <span style='color: #34d399;'>breach, br</span>                 - Initiate BREACH encounter (if target present)

        <span style='color: #fbbf24;'>NPCs:</span>
          <span style='color: #34d399;'>talk &lt;npc&gt;</span>                 - Talk to an NPC
          <span style='color: #34d399;'>ask &lt;npc&gt; about &lt;topic&gt;</span>    - Ask an NPC about a topic
          <span style='color: #34d399;'>give [qty|all] &lt;item&gt; to &lt;npc&gt;</span> - Hand item(s) to an NPC (for delivery missions)

        <span style='color: #fbbf24;'>Missions:</span>
          <span style='color: #34d399;'>missions</span>                   - List your active missions
          <span style='color: #34d399;'>mission &lt;slug&gt;</span>             - View details for a specific mission
          <span style='color: #34d399;'>ask &lt;npc&gt; about missions</span>   - See what work an NPC is offering
          <span style='color: #34d399;'>accept &lt;slug&gt;, acc, ac</span>     - Accept a mission (must be with giver)
          <span style='color: #34d399;'>abandon &lt;slug&gt;</span>             - Drop an active mission
          <span style='color: #34d399;'>turn_in &lt;slug&gt;, ti</span>         - Turn in a completed mission (must be with giver)

        <span style='color: #fbbf24;'>Fabrication:</span>
          <span style='color: #34d399;'>schematics, schem, sch</span>     - Browse available schematics
          <span style='color: #34d399;'>schematic &lt;slug&gt;</span>           - View schematic details &amp; ingredients
          <span style='color: #34d399;'>fabricate &lt;slug&gt;, fab</span>      - Fabricate an item from a schematic

        <span style='color: #fbbf24;'>Commerce:</span>
          <span style='color: #34d399;'>shop, browse</span>               - View vendor inventory &amp; prices
          <span style='color: #34d399;'>buy [qty] &lt;item&gt;</span>            - Purchase item(s) from vendor
          <span style='color: #34d399;'>sell [qty|all] &lt;item&gt;</span>      - Sell item(s) to vendor

        <span style='color: #fbbf24;'>Economy:</span>
          <span style='color: #34d399;'>cache</span>                      - List your caches
          <span style='color: #34d399;'>cache create</span>               - Create a new cache
          <span style='color: #34d399;'>cache balance [addr]</span>       - Check balance
          <span style='color: #34d399;'>cache history [addr]</span>       - Transaction history
          <span style='color: #34d399;'>cache send &lt;amt&gt; &lt;to&gt;</span>      - Send CRED (opts: from &lt;src&gt;, memo &lt;text&gt;)
          <span style='color: #34d399;'>cache default &lt;addr&gt;</span>       - Set default cache
          <span style='color: #34d399;'>cache name &lt;addr&gt; &lt;nick&gt;</span>   - Nickname a cache
          <span style='color: #34d399;'>cache abandon &lt;addr&gt;</span>       - Abandon a cache (WARNING: This is irreversible)

        <span style='color: #fbbf24;'>Ledger:</span>
          <span style='color: #34d399;'>chain latest</span>               - Recent global transactions
          <span style='color: #34d399;'>chain tx &lt;hash&gt;</span>            - Look up a transaction
          <span style='color: #34d399;'>chain cache &lt;addr&gt;</span>         - Public history for a cache
          <span style='color: #34d399;'>chain supply</span>               - CRED supply overview

        <span style='color: #fbbf24;'>Mining:</span>
          <span style='color: #34d399;'>rig</span>                        - Mining rig status
          <span style='color: #34d399;'>rig on / rig off</span>           - Toggle mining
          <span style='color: #34d399;'>rig install &lt;item&gt;</span>         - Install component (rig must be off)
          <span style='color: #34d399;'>rig uninstall &lt;item&gt;</span>       - Remove component (rig must be off)
          <span style='color: #34d399;'>rig inspect</span>                - Detailed rig view

        <span style='color: #fbbf24;'>Den:</span>
          <span style='color: #34d399;'>den</span>                        - View den status
          <span style='color: #34d399;'>den rename &lt;name&gt;</span>          - Rename your den (80 char max)
          <span style='color: #34d399;'>den describe &lt;text&gt;</span>        - Set den description
          <span style='color: #34d399;'>den invite &lt;hackr&gt;</span>         - Invite a hackr (1 hour)
          <span style='color: #34d399;'>den uninvite &lt;hackr&gt;</span>       - Revoke invite
          <span style='color: #34d399;'>den lock</span>                   - Lock den (blocks entry &amp; exit)
          <span style='color: #34d399;'>den unlock</span>                 - Unlock den
          <span style='color: #34d399;'>out</span>                        - Leave a den (shortcut for 'go out')

        <span style='color: #fbbf24;'>Fixtures:</span>
          <span style='color: #34d399;'>place &lt;f&gt;, install &lt;f&gt;</span>     - Install a fixture in your den
          <span style='color: #34d399;'>unplace &lt;f&gt;, uninstall &lt;f&gt;</span> - Uninstall a fixture (must be empty)
          <span style='color: #34d399;'>store [qty|all] &lt;item&gt; in &lt;f&gt;</span>     - Store item(s) in a fixture
          <span style='color: #34d399;'>put [qty|all] &lt;item&gt; in &lt;f&gt;</span>       - Same as store
          <span style='color: #34d399;'>retrieve [qty|all] &lt;item&gt; from &lt;f&gt;</span> - Retrieve item(s) from a fixture
          <span style='color: #34d399;'>peek &lt;f&gt;, search &lt;f&gt;</span>       - Inspect fixture contents

        <span style='color: #fbbf24;'>Social:</span>
          <span style='color: #34d399;'>say &lt;message&gt;</span>              - Say something in the room
          <span style='color: #34d399;'>who</span>                        - See who's online

        <span style='color: #fbbf24;'>Operative:</span>
          <span style='color: #34d399;'>stat, stats, st</span>            - View your operative profile
          <span style='color: #34d399;'>rep, reputation</span>            - View faction standings in detail
          <span style='color: #34d399;'>clear, cls, cl</span>             - Clear the screen
          <span style='color: #34d399;'>help, ?</span>                    - Show this help message
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
      output << "  <span style='color: #34d399;'>HEALTH      #{s["health"]}/#{hackr.effective_max("health")}</span>"
      output << "  <span style='color: #60a5fa;'>ENERGY      #{s["energy"]}/#{hackr.effective_max("energy")}</span>"
      output << "  <span style='color: #c084fc;'>PSYCHE      #{s["psyche"]}/#{hackr.effective_max("psyche")}</span>"

      # DECK status (if equipped)
      deck = hackr.equipped_deck
      if deck
        output << ""
        output << "<span style='color: #fbbf24;'>DECK:</span> <span style='color: #d0d0d0;'>#{h(deck.name)}</span> <span style='color: #6b7280;'>Battery: #{deck.deck_battery}/#{deck.deck_battery_max} | Slots: #{deck.deck_slots_used}/#{deck.deck_slot_count}</span>"
      end

      equipped_count = hackr.grid_items.equipped_by(hackr).count
      if equipped_count > 0
        output << ""
        output << "<span style='color: #fbbf24;'>LOADOUT:</span> <span style='color: #9ca3af;'>#{equipped_count}/#{GridItem::GEAR_SLOTS.size} slots</span> <span style='color: #6b7280;'>(use 'loadout' for details)</span>"
      end

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

    # --- Loadout commands ---

    def equip_command(item_name)
      return "<span style='color: #fbbf24;'>Equip what? Usage: equip &lt;item&gt;</span>" if item_name.empty?

      item = hackr.grid_items.in_inventory(hackr).find_by("LOWER(name) = ?", item_name.downcase)
      unless item
        candidate = hackr.grid_items.equipped_by(hackr).find_by("LOWER(name) = ?", item_name.downcase)
        if candidate
          return "<span style='color: #f87171;'>#{h(candidate.name)} is already equipped.</span>"
        end
        return "<span style='color: #f87171;'>You don't have '#{h(item_name)}'.</span>"
      end

      result = Grid::LoadoutService.equip!(hackr: hackr, item: item)

      slot_label = GridHackr::Loadout::GEAR_SLOT_LABELS[result.slot] || result.slot.upcase
      color = result.item.rarity_color
      name_display = result.item.unicorn? ? result.item.rainbow_name_html : "<span style='color: #{color};'>#{h(result.item.name)}</span>"

      lines = ["<span style='color: #34d399;'>Equipped </span>#{name_display}<span style='color: #9ca3af;'> → [#{slot_label}]</span>"]

      if result.swapped_item
        lines << "<span style='color: #9ca3af;'>  ↳ Swapped out: #{h(result.swapped_item.name)}</span>"
      end

      effects = result.item.gear_effects
      if effects.any?
        effect_parts = effects.reject { |_, v| v == 0 || v == false }.map do |key, val|
          label = h(key.to_s.tr("_", " "))
          (val == true) ? label : "#{label} +#{h(val.to_s)}"
        end
        lines << "<span style='color: #a78bfa;'>  Effects: #{effect_parts.join(", ")}</span>" if effect_parts.any?
      end

      output = lines.join("\n")

      notifications = []
      notifications += achievement_checker.check(:equip_item, item_name: result.item.name, slot: result.slot)
      notifications += mission_progressor.record(:equip_item, item_name: result.item.name)
      output = append_notifications(output, notifications) if notifications.any?

      output
    rescue Grid::LoadoutService::NotGear, Grid::LoadoutService::NoGearSlot => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue Grid::LoadoutService::ClearanceBlocked => e
      "<span style='color: #f87171;'>ACCESS DENIED — #{h(e.message)}</span>"
    rescue Grid::LoadoutService::ZoneRestricted, ArgumentError => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    end

    def unequip_command(item_name)
      return "<span style='color: #fbbf24;'>Unequip what? Usage: unequip &lt;item|slot&gt;</span>" if item_name.empty?

      # Allow "unequip <slot>" as alternative
      if GridItem::GEAR_SLOTS.include?(item_name.downcase)
        result = Grid::LoadoutService.unequip_by_slot!(hackr: hackr, slot: item_name.downcase)
        return format_unequip_output(result)
      end

      item = hackr.grid_items.equipped_by(hackr).find_by("LOWER(name) = ?", item_name.downcase)
      return "<span style='color: #f87171;'>You don't have '#{h(item_name)}' equipped.</span>" unless item

      result = Grid::LoadoutService.unequip!(hackr: hackr, item: item)
      format_unequip_output(result)
    rescue Grid::LoadoutService::NotEquipped => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue Grid::LoadoutService::ZoneRestricted => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    end

    def loadout_command
      loadout = hackr.loadout_by_slot

      lines = []
      lines << "<span style='color: #a78bfa;'>════════════════════════════════════════</span>"
      lines << "<span style='color: #22d3ee; font-weight: bold;'>LOADOUT :: #{h(hackr.hackr_alias)}</span>"
      lines << "<span style='color: #a78bfa;'>════════════════════════════════════════</span>"
      lines << ""

      GridItem::GEAR_SLOTS.each do |slot|
        label = GridHackr::Loadout::GEAR_SLOT_LABELS[slot] || slot.upcase
        item = loadout[slot]
        if item
          color = item.rarity_color
          name_display = item.unicorn? ? item.rainbow_name_html : "<span style='color: #{color};'>#{h(item.name)}</span>"
          rarity_tag = " <span style='color: #{color};'>[#{item.rarity_label}]</span>"
          effect_str = format_gear_effects(item.gear_effects)
          effect_tag = effect_str.present? ? " <span style='color: #6b7280;'>#{effect_str}</span>" : ""
          lines << "  <span style='color: #22d3ee;'>#{label.ljust(8)}</span> #{name_display}#{rarity_tag}#{effect_tag}"
        else
          lines << "  <span style='color: #22d3ee;'>#{label.ljust(8)}</span> <span style='color: #4b5563;'>-- empty --</span>"
        end
      end

      total_effects = hackr.loadout_effects
      if total_effects.any? { |_, v| v != 0 && v != false }
        lines << ""
        lines << "<span style='color: #fbbf24;'>Active Effects:</span>"
        total_effects.reject { |_, v| v == 0 || v == false }.each do |key, val|
          label = key.to_s.tr("_", " ")
          display = (val == true) ? label : "#{label}: +#{val}"
          lines << "  <span style='color: #34d399;'>#{h(display)}</span>"
        end
      end

      lines << "<span style='color: #a78bfa;'>════════════════════════════════════════</span>"
      lines.join("\n")
    end

    # ── DECK commands (outside BREACH) ─────────────────────────

    def deck_show_command
      deck = hackr.equipped_deck
      return "<span style='color: #f87171;'>No DECK equipped. Equip a DECK from your inventory first.</span>" unless deck

      output = []
      output << "<span style='color: #a78bfa;'>════════════════════════════════════════</span>"
      output << "<span style='color: #22d3ee; font-weight: bold;'>DECK :: #{h(deck.name)}</span> <span style='color: #{deck.rarity_color};'>[#{deck.rarity_label}]</span>"
      output << "<span style='color: #a78bfa;'>════════════════════════════════════════</span>"
      output << ""
      if deck.deck_fried?
        output << "<span style='color: #ef4444; font-weight: bold;'>STATUS: FRIED (level #{deck.deck_fried_level}/5) \u2014 unusable in BREACH</span>"
        output << "<span style='color: #9ca3af;'>Repair at a service node or use a DECK Repair Kit.</span>"
        output << ""
      end
      output << "<span style='color: #fbbf24;'>Battery:</span> <span style='color: #d0d0d0;'>#{deck.deck_battery}/#{deck.deck_battery_max}</span>"
      output << "<span style='color: #fbbf24;'>Software Slots:</span> <span style='color: #d0d0d0;'>#{deck.deck_slots_used}/#{deck.deck_slot_count}</span>"
      output << "<span style='color: #fbbf24;'>Module Slots:</span> <span style='color: #d0d0d0;'>#{deck.deck_modules_used}/#{deck.deck_module_slot_count}</span>"
      output << ""

      # Installed modules
      modules = deck.installed_modules.order(:name)
      if modules.any?
        output << "<span style='color: #fbbf24;'>Installed Modules:</span>"
        modules.each do |mod|
          firmware_slug = mod.properties&.dig("firmware_slug")
          firmware_label = firmware_slug ? "<span style='color: #34d399;'>firmware: #{h(firmware_slug)}</span>" : "<span style='color: #f87171;'>RAW — needs firmware</span>"
          output << "  <span style='color: #{mod.rarity_color};'>#{h(mod.name)}</span> #{firmware_label}"
        end
        output << ""
      end

      loaded = deck.loaded_software.order(:name)
      if loaded.any?
        output << "<span style='color: #fbbf24;'>Loaded Software:</span>"
        loaded.each do |sw|
          cat = sw.properties&.dig("software_category") || "unknown"
          cost = sw.properties&.dig("battery_cost") || 0
          slots = sw.properties&.dig("slot_cost") || 1
          mag = sw.properties&.dig("effect_magnitude") || 0
          color = sw.rarity_color
          output << "  <span style='color: #{color};'>#{h(sw.name)}</span> <span style='color: #6b7280;'>[#{cat}]</span> <span style='color: #9ca3af;'>slots:#{slots} pwr:#{cost} dmg:#{mag}</span>"
        end
      else
        output << "<span style='color: #6b7280;'>No software loaded. Use 'deck load &lt;software&gt;' to load programs.</span>"
      end

      output << "<span style='color: #a78bfa;'>════════════════════════════════════════</span>"
      output.join("\n")
    end

    def deck_subcommand(args)
      sub = args.first&.downcase
      name = args[1..]&.join(" ")

      case sub
      when "load"
        deck_load_command(name)
      when "unload"
        deck_unload_command(name)
      when "charge"
        deck_charge_command
      when "flash"
        deck_flash_command(args[1..])
      when "install"
        deck_install_command(name)
      when "uninstall"
        deck_uninstall_command(name)
      else
        "<span style='color: #fbbf24;'>Usage: deck [load|unload|charge|flash|install|uninstall] &lt;name&gt;</span>"
      end
    end

    def deck_load_command(software_name)
      return "<span style='color: #fbbf24;'>Load what? Usage: deck load &lt;software name&gt;</span>" if software_name.blank?

      deck = hackr.equipped_deck
      return "<span style='color: #f87171;'>No DECK equipped.</span>" unless deck

      software = hackr.grid_items.in_inventory(hackr)
        .where(item_type: "software")
        .find_by("LOWER(name) = ?", software_name.downcase)
      return "<span style='color: #f87171;'>No software named '#{h(software_name)}' in your inventory.</span>" unless software

      slot_cost = (software.properties&.dig("slot_cost") || 1).to_i
      if deck.deck_slots_available < slot_cost
        return "<span style='color: #f87171;'>Not enough DECK slots. Need #{slot_cost}, have #{deck.deck_slots_available} available.</span>"
      end

      error = nil
      ActiveRecord::Base.transaction do
        hackr.lock!
        deck.lock!
        if deck.deck_slots_available < slot_cost
          error = "<span style='color: #f87171;'>Not enough DECK slots. Need #{slot_cost}, have #{deck.deck_slots_available} available.</span>"
          raise ActiveRecord::Rollback
        end
        software.update!(deck_id: deck.id)
      end

      return error if error
      "<span style='color: #34d399;'>Loaded #{h(software.name)} into DECK.</span> <span style='color: #6b7280;'>(#{deck.deck_slots_used}/#{deck.deck_slot_count} slots)</span>"
    end

    def deck_unload_command(software_name)
      return "<span style='color: #fbbf24;'>Unload what? Usage: deck unload &lt;software name&gt;</span>" if software_name.blank?

      deck = hackr.equipped_deck
      return "<span style='color: #f87171;'>No DECK equipped.</span>" unless deck

      software = deck.loaded_software.find_by("LOWER(name) = ?", software_name.downcase)
      return "<span style='color: #f87171;'>No software named '#{h(software_name)}' loaded in your DECK.</span>" unless software

      ActiveRecord::Base.transaction do
        hackr.lock!
        software.update!(deck_id: nil)
      end

      "<span style='color: #34d399;'>Unloaded #{h(software.name)} from DECK.</span>"
    end

    def repair_command
      result = Grid::DeckRepairService.repair_at_npc!(hackr: hackr)
      result.display
    rescue Grid::DeckRepairService::NotAtRepairService => e
      "<span style='color: #9ca3af;'>#{h(e.message)}</span>"
    rescue Grid::DeckRepairService::NoDeckEquipped => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue Grid::DeckRepairService::DeckNotFried => e
      "<span style='color: #9ca3af;'>#{h(e.message)}</span>"
    rescue Grid::DeckRepairService::InsufficientBalance => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    end

    def deck_charge_command
      deck = hackr.equipped_deck
      return "<span style='color: #f87171;'>No DECK equipped.</span>" unless deck

      room = hackr.current_room
      can_charge = room&.owned_den_of?(hackr)

      unless can_charge
        return "<span style='color: #f87171;'>No charging source available. Charge your DECK at your den.</span>"
      end

      if deck.deck_battery >= deck.deck_battery_max
        return "<span style='color: #9ca3af;'>DECK battery is already full.</span>"
      end

      ActiveRecord::Base.transaction do
        hackr.lock!
        deck.reload
        deck.update!(properties: deck.properties.merge("battery_current" => deck.deck_battery_max))
      end

      "<span style='color: #34d399;'>DECK fully charged.</span> <span style='color: #d0d0d0;'>#{deck.deck_battery_max}/#{deck.deck_battery_max}</span>"
    end

    # ── Module flash/install/uninstall ───────────────────

    def deck_flash_command(args)
      # Syntax: deck flash <firmware> onto <module>
      # At firmware_vendor room: firmware bought + flashed in one step
      # With EEPROM Flasher tool: firmware from inventory + flash anywhere
      args ||= []
      raw = args.join(" ")

      # Parse "firmware onto module" syntax
      parts = raw.split(/\s+onto\s+/i, 2)
      if parts.length != 2 || parts.any?(&:blank?)
        return "<span style='color: #fbbf24;'>Usage: deck flash &lt;firmware&gt; onto &lt;module&gt;</span>"
      end

      firmware_name = parts[0].strip
      module_name = parts[1].strip

      deck = hackr.equipped_deck
      return "<span style='color: #f87171;'>No DECK equipped.</span>" unless deck

      # Find the module in inventory (must be unflashed OR reflash overwrites)
      mod = hackr.grid_items.in_inventory(hackr)
        .where(item_type: "module")
        .find_by("LOWER(name) = ?", module_name.downcase)
      return "<span style='color: #f87171;'>No module named '#{h(module_name)}' in your inventory.</span>" unless mod

      room = hackr.current_room
      at_vendor = room&.room_type == "firmware_vendor"
      has_flasher = hackr.grid_items.in_inventory(hackr)
        .joins(:grid_item_definition)
        .exists?(grid_item_definitions: {slug: "eeprom-flasher"})

      unless at_vendor || has_flasher
        return "<span style='color: #f87171;'>You need an EEPROM Flasher tool or a Firmware Vending Machine to flash firmware.</span>"
      end

      # Find firmware
      firmware = if at_vendor
        # At vendor: firmware available from vendor catalog (just need definition)
        GridItemDefinition.where(item_type: "firmware")
          .find_by("LOWER(name) = ?", firmware_name.downcase)
      else
        # DIY: firmware must be in inventory
        hackr.grid_items.in_inventory(hackr)
          .where(item_type: "firmware")
          .find_by("LOWER(name) = ?", firmware_name.downcase)
      end

      if firmware.nil?
        location_hint = at_vendor ? "available at this vendor" : "in your inventory"
        return "<span style='color: #f87171;'>No firmware named '#{h(firmware_name)}' #{location_hint}.</span>"
      end

      firmware_def = at_vendor ? firmware : firmware.grid_item_definition

      # Check compatibility: firmware's compatible_modules must include module definition slug
      compatible = firmware_def.properties&.dig("compatible_modules")
      mod_slug = mod.grid_item_definition.slug
      if compatible.is_a?(Array) && compatible.any? && !compatible.include?(mod_slug)
        return "<span style='color: #f87171;'>#{h(firmware_def.name)} is not compatible with #{h(mod.name)}.</span>"
      end

      # Vendor cost check
      if at_vendor
        cost = firmware_def.value
        cache = hackr.default_cache
        if cost > 0 && (!cache&.active? || cache.balance < cost)
          return "<span style='color: #f87171;'>Insufficient CRED. Cost: #{cost}.</span>"
        end
      end

      old_firmware = mod.properties&.dig("firmware_slug")
      ActiveRecord::Base.transaction do
        hackr.lock!
        mod.lock!

        # Pay at vendor
        if at_vendor
          cost = firmware_def.value
          if cost > 0
            Grid::TransactionService.burn!(
              from_cache: hackr.default_cache,
              amount: cost,
              memo: "Firmware: #{firmware_def.name}"
            )
          end
        elsif firmware.quantity > 1
          # DIY: consume firmware item from inventory
          firmware.update!(quantity: firmware.quantity - 1)
        else
          firmware.destroy!
        end

        # Flash firmware onto module (overwrites previous)
        mod.update!(properties: (mod.properties || {}).merge(
          "flashed" => true,
          "firmware_slug" => firmware_def.slug,
          "firmware_name" => firmware_def.name
        ))
      end

      output = "<span style='color: #34d399;'>Firmware flashed: #{h(firmware_def.name)} → #{h(mod.name)}.</span>"
      output += " <span style='color: #6b7280;'>Previous firmware overwritten.</span>" if old_firmware.present?
      output
    end

    def deck_install_command(module_name)
      return "<span style='color: #fbbf24;'>Install what? Usage: deck install &lt;module name&gt;</span>" if module_name.blank?

      if hackr.in_breach?
        return "<span style='color: #f87171;'>Cannot install modules during a BREACH.</span>"
      end

      deck = hackr.equipped_deck
      return "<span style='color: #f87171;'>No DECK equipped.</span>" unless deck

      mod = hackr.grid_items.in_inventory(hackr)
        .where(item_type: "module")
        .find_by("LOWER(name) = ?", module_name.downcase)
      return "<span style='color: #f87171;'>No module named '#{h(module_name)}' in your inventory.</span>" unless mod

      unless mod.properties&.dig("flashed")
        return "<span style='color: #f87171;'>#{h(mod.name)} has no firmware. Flash firmware onto it first.</span>"
      end

      if deck.deck_modules_available <= 0
        return "<span style='color: #f87171;'>No module slots available. Uninstall a module first. (#{deck.deck_modules_used}/#{deck.deck_module_slot_count})</span>"
      end

      error = nil
      ActiveRecord::Base.transaction do
        hackr.lock!
        deck.lock!

        if deck.deck_modules_available <= 0
          error = "<span style='color: #f87171;'>No module slots available.</span>"
          raise ActiveRecord::Rollback
        end

        mod.update!(deck_id: deck.id)
      end

      return error if error
      "<span style='color: #34d399;'>Installed #{h(mod.name)} into DECK.</span> <span style='color: #6b7280;'>(#{deck.deck_modules_used}/#{deck.deck_module_slot_count} module slots)</span>"
    end

    def deck_uninstall_command(module_name)
      return "<span style='color: #fbbf24;'>Uninstall what? Usage: deck uninstall &lt;module name&gt;</span>" if module_name.blank?

      if hackr.in_breach?
        return "<span style='color: #f87171;'>Cannot uninstall modules during a BREACH.</span>"
      end

      deck = hackr.equipped_deck
      return "<span style='color: #f87171;'>No DECK equipped.</span>" unless deck

      mod = deck.installed_modules.find_by("LOWER(name) = ?", module_name.downcase)
      return "<span style='color: #f87171;'>No module named '#{h(module_name)}' installed in your DECK.</span>" unless mod

      ActiveRecord::Base.transaction do
        hackr.lock!
        mod.update!(deck_id: nil)
      end

      "<span style='color: #34d399;'>Uninstalled #{h(mod.name)} from DECK.</span>"
    end

    # ── BREACH initiation (outside BREACH) ───────────────────

    def breach_initiate_command(target_name)
      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless room

      encounters = Grid::BreachService.available_encounters(room: room, hackr: hackr)
      if encounters.empty?
        return "<span style='color: #f87171;'>Nothing to breach here.</span>"
      end

      encounter = resolve_breach_target(encounters, target_name)
      unless encounter
        return "<span style='color: #f87171;'>No matching breach target. Type 'look' to see available targets.</span>"
      end

      result = Grid::BreachService.start!(hackr: hackr, encounter: encounter)

      output = []
      output << ""
      output << "<span style='color: #22d3ee; font-weight: bold;'>Initiating BREACH...</span>"
      output << ""
      output << result.display
      output << ""
      output << "<span style='color: #6b7280;'>Type 'help' for BREACH commands.</span>"
      output.join("\n")
    rescue Grid::BreachService::AlreadyInBreach => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue Grid::BreachService::NoDeckEquipped => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue Grid::BreachService::ClearanceBlocked => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue Grid::BreachService::TemplateGated => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    end

    # Resolve breach target from name or number
    def resolve_breach_target(encounters, target_name)
      # Single encounter + no target specified → auto-select
      return encounters.first if encounters.size == 1 && target_name.blank?

      # Must specify target when multiple encounters
      return nil if target_name.blank? && encounters.size > 1

      target = target_name.to_s.strip

      # Try numeric index first (1-based)
      if target.match?(/\A\d+\z/)
        idx = target.to_i - 1
        return encounters[idx] if idx >= 0 && idx < encounters.size
        return nil # Out-of-range number — don't fall through to name search
      end

      # Try name match (case-insensitive, partial)
      encounters.find { |enc| enc.name.downcase.include?(target.downcase) }
    end

    def equipped_item_hint(item_name)
      return nil unless hackr.grid_items.equipped_by(hackr).find_by("LOWER(name) = ?", item_name.downcase)
      "<span style='color: #f87171;'>That item is equipped. Use 'unequip #{h(item_name)}' first.</span>"
    end

    def format_unequip_output(result)
      slot_label = GridHackr::Loadout::GEAR_SLOT_LABELS[result.slot] || result.slot.upcase
      color = result.item.rarity_color
      name_display = result.item.unicorn? ? result.item.rainbow_name_html : "<span style='color: #{color};'>#{h(result.item.name)}</span>"

      lines = ["<span style='color: #34d399;'>Unequipped </span>#{name_display}<span style='color: #9ca3af;'> from [#{slot_label}]</span>"]
      result.vitals_clamped.each do |clamp|
        lines << "<span style='color: #f87171;'>  ↳ #{clamp[:vital].capitalize} reduced to #{clamp[:new_value]} (cap lowered)</span>"
      end
      lines.join("\n")
    end

    def format_gear_effects(effects)
      return "" if effects.blank?
      parts = effects.reject { |_, v| v == 0 || v == false }.map do |key, val|
        label = h(key.to_s.tr("_", " "))
        (val == true) ? label : "+#{h(val.to_s)} #{label}"
      end
      parts.any? ? "[#{parts.join(", ")}]" : ""
    end

    def use_command(item_name)
      return "<span style='color: #fbbf24;'>Use what?</span>" if item_name.empty?

      item = hackr.grid_items.find_by("LOWER(name) = ?", item_name.downcase)
      return "<span style='color: #f87171;'>You don't have '#{h(item_name)}'.</span>" unless item

      saved_name = item.name
      result = apply_item_effect_with_notifications(item)
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
      notifications += mission_progressor.record(:use_item, item_name: saved_name)
      output = append_notifications(result, notifications)
      {output: output, event: nil}
    end

    def salvage_command(item_name)
      parsed = Grid::QuantityParser.parse(item_name)
      item_name = parsed.remainder
      return "<span style='color: #fbbf24;'>Salvage what?</span>" if item_name.empty?

      item = hackr.grid_items.in_inventory(hackr).find_by("LOWER(name) = ?", item_name.downcase)
      return equipped_item_hint(item_name) || "<span style='color: #f87171;'>You don't have '#{h(item_name)}'.</span>" unless item

      if item.unicorn?
        return "<span style='color: #f87171;'>UNICORN items are irreducible. They cannot be salvaged.</span>"
      end

      item_styled = h(item.name)
      begin
        result = Grid::SalvageService.salvage!(hackr: hackr, item: item, quantity: parsed.quantity)
      rescue ArgumentError => e
        return "<span style='color: #f87171;'>#{h(e.message)}</span>"
      end

      qty = result.quantity_salvaged
      increment_stat!("salvage_count", qty)

      level_msg = result.xp_result[:leveled_up] ?
        "\n<span style='color: #fbbf24; font-weight: bold;'>▲ CLEARANCE INCREASED TO #{result.xp_result[:new_clearance]}!</span>" : ""
      qty_label = (qty > 1) ? " ×#{qty}" : ""
      output = "<span style='color: #34d399;'>You salvage </span>#{item_styled}" \
        "<span style='color: #34d399;'>#{h(qty_label)}. +#{result.xp_awarded} XP.</span>#{level_msg}"

      result.yielded_items.each do |yi|
        output += "\n<span style='color: #a78bfa;'>  ▸ Decomposed: </span>" \
          "<span style='color: #d0d0d0;'>#{h(yi[:name])}</span>" \
          "<span style='color: #6b7280;'> ×#{yi[:quantity]}</span>"
      end

      notifications = achievement_checker.check(:salvage_item)
      notifications += achievement_checker.check(:salvage_count)
      notifications += mission_progressor.record(:salvage_item, item_name: result.item_name, amount: qty)

      if result.yielded_items.any?
        total_yield_qty = result.yielded_items.sum { |yi| yi[:quantity] }
        increment_stat!("salvage_yield_count", total_yield_qty)

        result.yielded_items.each do |yi|
          notifications += achievement_checker.check(:salvage_yield_received)
          notifications += mission_progressor.record(:salvage_yield_received, item_name: yi[:name], amount: yi[:quantity])
        end

        notifications += achievement_checker.check(:salvage_yield_count)
      end

      notifications += mission_progressor.record(:reach_clearance, clearance: hackr.stat("clearance").to_i)
      output = append_notifications(output, notifications)
      {output: output, event: nil}
    rescue Grid::InventoryErrors::InventoryFull, Grid::InventoryErrors::StackLimitExceeded => e
      "<span style='color: #f87171;'>Salvage aborted — #{h(e.message)}</span>"
    end

    def analyze_command(item_name)
      return "<span style='color: #fbbf24;'>Analyze what?</span>" if item_name.empty?

      item = hackr.grid_items.find_by("LOWER(name) = ?", item_name.downcase)
      return "<span style='color: #f87171;'>You don't have '#{h(item_name)}'.</span>" unless item

      if item.unicorn?
        return "<span style='color: #f87171;'>UNICORN items are irreducible. They cannot be salvaged.</span>"
      end

      xp_amount = [item.value, 1].max
      yields = item.grid_item_definition.salvage_yields.ordered.includes(:output_definition)

      output = "<span style='color: #22d3ee;'>▸ ANALYSIS :: </span><span style='color: #d0d0d0;'>#{h(item.name)}</span>"
      output += "\n<span style='color: #6b7280;'>  XP yield: </span><span style='color: #34d399;'>+#{xp_amount} XP</span>"

      if yields.any?
        output += "\n<span style='color: #6b7280;'>  Decomposition yields:</span>"
        yields.each do |y|
          output += "\n<span style='color: #a78bfa;'>    ▸ </span>" \
            "<span style='color: #d0d0d0;'>#{h(y.output_definition.name)}</span>" \
            "<span style='color: #6b7280;'> ×#{y.quantity}</span>"
        end
      else
        output += "\n<span style='color: #6b7280;'>  No decomposition yields. XP only.</span>"
      end

      output
    end

    # --- Fabrication commands ---

    def schematics_command
      all_schematics = GridSchematic.published.ordered
        .includes(:output_definition, ingredients: :input_definition).to_a

      inventory_qtys = hackr.grid_items.group(:grid_item_definition_id).sum(:quantity)
      gate_ctx = schematic_gate_context

      available, locked = all_schematics.partition { |s| s.craftable_by?(hackr, **gate_ctx) }

      output = []
      output << "\n<span style='color: #a78bfa;'>════════════════════════════════════════════════════════════════</span>"
      output << "<span style='color: #22d3ee; font-weight: bold;'>FABRICATION SCHEMATICS</span>"
      output << "<span style='color: #a78bfa;'>════════════════════════════════════════════════════════════════</span>"

      if all_schematics.empty?
        output << ""
        output << "<span style='color: #9ca3af;'>No schematics available.</span>"
      else
        if available.any?
          output << ""
          output << "<span style='color: #34d399; font-weight: bold;'>[AVAILABLE]</span>"
          available.each do |s|
            ingredients_line = s.ingredients.ordered
              .map { |i| "#{h(i.input_definition.name)} ×#{i.quantity}" }.join(", ")
            has_mats = s.ingredients.all? { |i| (inventory_qtys[i.input_definition_id] || 0) >= i.quantity }
            badge = has_mats ? "<span style='color: #34d399;'>✓</span>" : "<span style='color: #f87171;'>✗</span>"
            output << "  #{badge} <span style='color: #60a5fa;'>#{h(s.slug)}</span> " \
              "<span style='color: #9ca3af;'>— #{h(s.name)}</span> " \
              "<span style='color: #6b7280;'>[ #{ingredients_line} ]</span>"
          end
        end

        if locked.any?
          output << ""
          output << "<span style='color: #6b7280; font-weight: bold;'>[LOCKED]</span>"
          locked.each do |s|
            output << "  <span style='color: #4b5563;'>◈ #{h(s.name)}</span>"
          end
        end
      end

      output << ""
      output << "<span style='color: #6b7280;'>Use 'schematic &lt;slug&gt;' for details. Use 'fab &lt;slug&gt;' to fabricate.</span>"
      output << "<span style='color: #a78bfa;'>════════════════════════════════════════════════════════════════</span>"
      output.join("\n")
    end

    def schematic_detail_command(slug)
      return "<span style='color: #fbbf24;'>Which schematic? Usage: schematic &lt;slug&gt;</span>" if slug.blank?

      schematic = GridSchematic.published
        .includes(:output_definition, ingredients: :input_definition)
        .find_by(slug: slug.downcase)
      return "<span style='color: #f87171;'>Unknown schematic: #{h(slug)}. Use 'schematics' to browse.</span>" unless schematic

      output = []
      output << "\n<span style='color: #a78bfa;'>════════════════════════════════════════════════════════════════</span>"
      output << "<span style='color: #60a5fa; font-weight: bold;'>#{h(schematic.name)}</span> <span style='color: #6b7280;'>[#{h(schematic.slug)}]</span>"
      output << "<span style='color: #9ca3af;'>#{h(schematic.description)}</span>" if schematic.description.present?
      output << ""
      output << "<span style='color: #fbbf24;'>OUTPUT:</span> " \
        "<span style='color: #{schematic.output_definition.rarity_color};'>#{h(schematic.output_definition.name)}</span>" \
        "#{" <span style='color: #6b7280;'>×#{schematic.output_quantity}</span>" if schematic.output_quantity > 1}"
      output << "<span style='color: #fbbf24;'>XP REWARD:</span> <span style='color: #a78bfa;'>+#{schematic.xp_reward}</span>" if schematic.xp_reward.positive?
      if schematic.required_clearance.positive?
        output << "<span style='color: #fbbf24;'>CLEARANCE:</span> <span style='color: #d0d0d0;'>#{schematic.required_clearance}+</span>"
      end
      if schematic.required_room_type.present?
        label = GridSchematic::ROOM_TYPE_LABELS[schematic.required_room_type] || schematic.required_room_type
        output << "<span style='color: #fbbf24;'>REQUIRES:</span> <span style='color: #f59e0b;'>#{h(label)}</span>"
      end
      output << ""
      output << "<span style='color: #fbbf24;'>INGREDIENTS:</span>"
      inventory_qtys = hackr.grid_items.group(:grid_item_definition_id).sum(:quantity)
      can_craft = true
      schematic.ingredients.ordered.each do |ing|
        owned = inventory_qtys[ing.input_definition_id] || 0
        can_craft = false if owned < ing.quantity
        status = (owned >= ing.quantity) ?
          "<span style='color: #34d399;'>✓ #{owned}/#{ing.quantity}</span>" :
          "<span style='color: #f87171;'>✗ #{owned}/#{ing.quantity}</span>"
        output << "  #{status} <span style='color: #d0d0d0;'>#{h(ing.input_definition.name)}</span>"
      end
      output << ""
      output << (can_craft ?
        "<span style='color: #34d399;'>★ Ready to fabricate. Use: fab #{h(schematic.slug)}</span>" :
        "<span style='color: #6b7280;'>Missing ingredients. Gather materials and try again.</span>")
      output << "<span style='color: #a78bfa;'>════════════════════════════════════════════════════════════════</span>"
      output.join("\n")
    end

    def fabricate_command(recipe_slug)
      return "<span style='color: #fbbf24;'>Fabricate what? Usage: fab &lt;schematic-slug&gt;</span>" if recipe_slug.blank?

      schematic = GridSchematic.published
        .includes(:output_definition, ingredients: :input_definition)
        .find_by(slug: recipe_slug.downcase)
      return "<span style='color: #f87171;'>Unknown schematic: #{h(recipe_slug)}. Use 'schematics' to browse.</span>" unless schematic

      unless schematic.craftable_by?(hackr, **schematic_gate_context, current_room: hackr.current_room)
        return craftability_error_for(schematic)
      end

      begin
        result = Grid::FabricationService.fabricate!(hackr: hackr, schematic: schematic)
      rescue Grid::FabricationService::IngredientsInsufficient => e
        return "<span style='color: #f87171;'>#{h(e.message)}</span>"
      rescue Grid::InventoryErrors::InventoryFull => e
        return "<span style='color: #f87171;'>Fabrication aborted — #{h(e.message)}</span>"
      rescue Grid::InventoryErrors::StackLimitExceeded => e
        return "<span style='color: #f87171;'>Fabrication aborted — #{h(e.message)}</span>"
      end

      level_msg = result.xp_result[:leveled_up] ?
        "\n<span style='color: #fbbf24; font-weight: bold;'>▲ CLEARANCE INCREASED TO #{result.xp_result[:new_clearance]}!</span>" : ""
      qty_display = (result.output_quantity > 1) ? " <span style='color: #6b7280;'>×#{result.output_quantity}</span>" : ""
      output = "<span style='color: #34d399;'>Fabricated: </span>" \
        "<span style='color: #60a5fa; font-weight: bold;'>#{h(result.output_item_name)}</span>#{qty_display}" \
        "<span style='color: #34d399;'>.</span>" \
        "#{" <span style='color: #a78bfa;'>+#{result.xp_awarded} XP</span>" if result.xp_awarded.positive?}#{level_msg}"

      notifications = achievement_checker.check(:fabricate_item, item_name: result.output_item_name)
      notifications += achievement_checker.check(:fabricate_count)
      notifications += mission_progressor.record(:fabricate_item, item_name: result.output_item_name)
      notifications += mission_progressor.record(:reach_clearance, clearance: hackr.stat("clearance").to_i)
      output = append_notifications(output, notifications)
      {output: output, event: nil}
    end

    # Delegates to Grid::ItemEffectApplier#apply_item_effect.
    # Wraps redeem_den to add achievement notifications (CommandParser-specific).
    def apply_item_effect_with_notifications(item)
      result = apply_item_effect(item)

      # Den creation triggers achievements (only relevant outside BREACH)
      if item.properties&.dig("effect_type") == "redeem_den" && result.is_a?(String) && result.include?("DEN PROVISIONED")
        notifications = achievement_checker.check(:den_created)
        return append_notifications(result, notifications)
      end

      result
    end

    def examine_hackr(target_hackr)
      cl = target_hackr.stat("clearance")
      achievements = target_hackr.grid_achievements.order(:name)
      loadout = target_hackr.loadout_by_slot

      output = []
      output << "<span style='color: #a78bfa; font-weight: bold;'>#{h(target_hackr.hackr_alias)}</span> <span style='color: #9ca3af;'>:: CLEARANCE #{cl}</span>"

      equipped_slots = loadout.select { |_, item| item }
      if equipped_slots.any?
        output << ""
        output << "<span style='color: #fbbf24;'>LOADOUT:</span>"
        equipped_slots.each do |slot, item|
          label = GridHackr::Loadout::GEAR_SLOT_LABELS[slot] || slot.upcase
          name_display = item.unicorn? ? item.rainbow_name_html : "<span style='color: #{item.rarity_color};'>#{h(item.name)}</span>"
          output << "  <span style='color: #22d3ee;'>#{label.ljust(8)}</span> #{name_display}"
        end
      end

      if achievements.any?
        output << ""
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
      if item.rig_component? && item.slot.present? && item.properties&.key?("rate_multiplier")
        props = item.properties || {}
        slot = props["slot"]&.upcase || "UNKNOWN"
        output += "\n<span style='color: #22d3ee;'>Slot: #{slot}</span>"
        output += " <span style='color: #fbbf24;'>Multiplier: x#{item.rate_multiplier}</span>"
        if slot == "MOTHERBOARD"
          output += "\n<span style='color: #9ca3af;'>Slots: CPU #{props["cpu_slots"] || 0} / GPU #{props["gpu_slots"] || 0} / RAM #{props["ram_slots"] || 0}</span>"
        end
      end
      props = item.properties || {}
      if props["effect_type"] == "redeem_den"
        output += "\n<span style='color: #a78bfa;'>▸ USE this item to claim a private den in the Residential District.</span>"
        output += "\n<span style='color: #9ca3af;'>  Type: <span style='color: #22d3ee;'>use #{h(item.name.downcase)}</span></span>"
      end
      if item.fixture?
        cap = item.storage_capacity
        if item.placed?
          used = item.stored_items.count
          output += "\n<span style='color: #a78bfa;'>Storage Fixture</span> <span style='color: #34d399;'>[PLACED]</span> <span style='color: #9ca3af;'>#{used}/#{cap} slots used</span>"
          output += "\n<span style='color: #9ca3af;'>  Inspect: <span style='color: #22d3ee;'>peek #{h(item.name.downcase)}</span></span>"
        else
          output += "\n<span style='color: #a78bfa;'>Storage Fixture</span> <span style='color: #6b7280;'>[in inventory]</span> <span style='color: #9ca3af;'>#{cap} slots</span>"
          output += "\n<span style='color: #9ca3af;'>  Place in your den: <span style='color: #22d3ee;'>place #{h(item.name.downcase)}</span></span>"
        end
      end
      if item.gear?
        slot_label = item.gear_slot&.upcase&.tr("_", " ") || "UNKNOWN"
        status = item.equipped? ? "<span style='color: #34d399;'>[EQUIPPED]</span>" : "<span style='color: #6b7280;'>[in inventory]</span>"
        output += "\n<span style='color: #22d3ee;'>Gear Slot: #{slot_label}</span> #{status}"
        output += " <span style='color: #fbbf24;'>Requires CLEARANCE #{item.required_clearance}</span>" if item.required_clearance > 0
        effects = item.gear_effects
        if effects.any?
          output += "\n<span style='color: #a78bfa;'>Effects:</span>"
          effects.each do |key, val|
            label = key.to_s.tr("_", " ")
            output += "\n  <span style='color: #34d399;'>#{h(label)}: #{h(val.to_s)}</span>"
          end
        end
        unless item.equipped?
          output += "\n<span style='color: #9ca3af;'>  Equip: <span style='color: #22d3ee;'>equip #{h(item.name.downcase)}</span></span>"
        end
      end
      output
    end

    def examine_listing(listing, effective_price)
      color = listing.rarity_color
      rarity_tag = listing.rarity ? " <span style='color: #{color};'>[#{listing.rarity_label}]</span>" : ""
      output = "<span style='color: #d0d0d0;'>#{codex_linkify(listing.description)}</span>#{rarity_tag}"
      output += "\n<span style='color: #6b7280;'>Buy: <span style='color: #34d399;'>#{format_cred(effective_price)} CRED</span> / Sell: #{format_cred(listing.sell_price)} CRED</span>"
      if listing.item_type == "rig_component"
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

    # Render the hackr's current position in a mob's dialogue tree.
    # Used by talk_command and back navigation. No side effects.
    def render_dialogue_position(mob, nav)
      content = []

      if nav.at_root?
        content << "<span style='color: #c084fc;'>#{h(mob.name)}</span>: <span style='color: #60a5fa;'>\"#{h(nav.greeting)}\"</span>"
      else
        breadcrumb = nav.current_path.map { |k| h(k).to_s }.join(" > ")
        content << "<span style='color: #9ca3af;'>[#{breadcrumb}]</span>"
        content << ""
        content << "<span style='color: #c084fc;'>#{h(mob.name)}</span> waits for your question."
      end

      append_topic_list(content, nav.current_topics)

      unless nav.at_root?
        content << "<span style='color: #6b7280;'>Use 'ask #{h(mob.name)} about back' to go up, or 'talk to #{h(mob.name)} again' to start over.</span>"
      end

      dialogue_box(content.join("\n"))
    end

    def dialogue_box(content)
      # Create a thin-bordered box around dialogue content
      # Add blank line before box, strip content to avoid blank lines inside
      "\n<div style='border: 1px solid #666; padding: 10px; margin: 5px 0; background: #0d0d0d;'>#{content.strip}</div>"
    end

    # Check if a mission's dialogue_path gate blocks the current hackr.
    def dialogue_path_blocked?(mission, mob)
      required = mission.dialogue_path
      return false if required.blank?
      return false unless required.is_a?(Array)

      current = hackr.dialogue_path_for(mob)
      !(required.length <= current.length && current.first(required.length) == required)
    end

    def append_topic_list(content, topics)
      return unless topics.any?
      content << ""
      labels = topics.map do |key, node|
        if DialogueNavigator.has_children?(node)
          "#{h(key)} <span style='color: #6b7280;'>[+]</span>"
        else
          h(key).to_s
        end
      end
      content << "<span style='color: #9ca3af;'>You can ask about:</span> <span style='color: #fbbf24;'>#{labels.join(", ")}</span>"
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
      parsed = Grid::QuantityParser.parse(item_name)
      item_name = parsed.remainder
      return "<span style='color: #fbbf24;'>Buy what? Usage: buy [qty] &lt;item&gt;</span>" if item_name.empty?

      return "<span style='color: #f87171;'>Specify a number to buy, not 'all'.</span>" if parsed.quantity == :all
      qty = parsed.quantity

      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless room

      vendor = room.grid_mobs.find_by(mob_type: "vendor")
      return "<span style='color: #9ca3af;'>There's no vendor here.</span>" unless vendor

      result = Grid::ShopService.buy!(hackr: hackr, mob: vendor, item_name: item_name, quantity: qty)

      item = result[:item]
      color = item.rarity_color
      name_display = item.unicorn? ? item.rainbow_name_html : "<span style='color: #{color};'>#{h(item.name)}</span>"
      qty_label = (qty > 1) ? " ×#{qty}" : ""

      output = "<span style='color: #34d399;'>Purchased </span>#{name_display}<span style='color: #34d399;'>#{h(qty_label)} for <span style='color: #fbbf24;'>#{format_cred(result[:price_paid])} CRED</span>. Balance: #{format_cred(result[:new_balance])} CRED.</span>"

      rep_notif = grant_faction_rep(vendor.grid_faction, 2, reason: "buy:#{slugify(item.name)}", source: vendor)
      notifications = achievement_checker.check(:purchase_item, item_name: item.name)
      notifications.unshift(rep_notif) if rep_notif
      notifications += mission_progressor.record(:buy_item, item_name: item.name, amount: qty)
      notifications += mission_progressor.record(:spend_cred, amount: result[:price_paid].to_i)
      if vendor.grid_faction
        notifications += mission_progressor.record(
          :reach_rep,
          faction_slug: vendor.grid_faction.slug,
          rep_value: reputation_service.effective_rep(vendor.grid_faction)
        )
      end
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
    rescue Grid::InventoryErrors::InventoryFull => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    end

    def sell_command(item_name)
      parsed = Grid::QuantityParser.parse(item_name)
      item_name = parsed.remainder
      return "<span style='color: #fbbf24;'>Sell what? Usage: sell [qty|all] &lt;item&gt;</span>" if item_name.empty?

      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless room

      vendor = room.grid_mobs.find_by(mob_type: "vendor")
      return "<span style='color: #9ca3af;'>There's no vendor here.</span>" unless vendor

      result = Grid::ShopService.sell!(hackr: hackr, mob: vendor, item_name: item_name, quantity: parsed.quantity)

      qty = result[:quantity]
      qty_label = (qty > 1) ? " ×#{qty}" : ""
      "<span style='color: #34d399;'>Sold </span><span style='color: #d0d0d0;'>#{h(result[:item_name])}</span><span style='color: #34d399;'>#{h(qty_label)} for <span style='color: #fbbf24;'>#{format_cred(result[:sell_price])} CRED</span>. Balance: #{format_cred(result[:new_balance])} CRED.</span>"
    rescue Grid::ShopService::AccessDenied => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue Grid::ShopService::ItemNotFound
      equipped_item_hint(item_name) || "<span style='color: #f87171;'>You don't have '#{h(item_name)}'.</span>"
    rescue Grid::ShopService::InsufficientStock => e
      "<span style='color: #fbbf24;'>#{h(e.message)}</span>"
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
      return "<span style='color: #f87171;'>Your rig isn't here. It's in your Den.</span>" unless in_own_den?
      return "<span style='color: #f87171;'>Your rig must be powered down before modifying components. Use 'rig off' first.</span>" if rig.active?

      item = hackr.grid_items.where(grid_mining_rig_id: nil).find_by("LOWER(name) = ?", item_name.downcase)
      return "<span style='color: #f87171;'>You don't have '#{h(item_name)}' in your inventory.</span>" unless item
      return "<span style='color: #f87171;'>#{h(item.name)} is not a rig component.</span>" unless item.rig_component?

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
      return "<span style='color: #f87171;'>Your rig isn't here. It's in your Den.</span>" unless in_own_den?
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

    def mission_service
      @mission_service ||= Grid::MissionService.new(hackr)
    end

    def mission_progressor
      @mission_progressor ||= Grid::MissionProgressor.new(hackr)
    end

    def in_own_den?
      hackr.current_room&.owned_den_of?(hackr)
    end

    def craftability_error_for(schematic)
      if schematic.required_room_type.present? && schematic.craftable_by?(hackr, **schematic_gate_context)
        "<span style='color: #f87171;'>You can only fabricate this item at #{schematic.room_type_label}.</span>"
      else
        "<span style='color: #f87171;'>You don't meet the requirements for this schematic.</span>"
      end
    end

    # Pre-loaded gate context for schematic craftable_by? checks.
    # Memoized per request — safe because CommandParser is single-use.
    def schematic_gate_context
      @schematic_gate_context ||= {
        completed_mission_slugs: hackr.grid_hackr_missions
          .where(status: "completed").joins(:grid_mission)
          .pluck("grid_missions.slug").to_set,
        earned_achievement_slugs: hackr.grid_hackr_achievements
          .joins(:grid_achievement)
          .pluck("grid_achievements.slug").to_set
      }
    end

    # --- Mission commands ---

    def missions_command
      active = mission_service.active_hackr_missions.to_a
      completed = mission_service.completed_hackr_missions(limit: 5).to_a

      output = []
      output << "\n<span style='color: #a78bfa;'>════════════════════════════════════════════════════════════════</span>"
      output << "<span style='color: #22d3ee; font-weight: bold;'>ACTIVE MISSIONS</span>"
      output << "<span style='color: #a78bfa;'>════════════════════════════════════════════════════════════════</span>"

      if active.empty?
        output << ""
        output << "<span style='color: #9ca3af;'>You have no active missions.</span>"
        output << "<span style='color: #6b7280;'>Talk to NPCs and 'ask &lt;npc&gt; about missions' to find work.</span>"
      else
        active.each do |hm|
          output << ""
          output << format_active_mission_row(hm)
        end
      end

      if completed.any?
        output << ""
        output << "<span style='color: #fbbf24;'>Recently completed:</span>"
        completed.each do |hm|
          m = hm.grid_mission
          output << "  <span style='color: #34d399;'>✓</span> <span style='color: #6b7280;'>#{h(m.slug)}</span> " \
            "<span style='color: #9ca3af;'>::</span> <span style='color: #d0d0d0;'>#{h(m.name)}</span>" +
            ((hm.turn_in_count.to_i > 1) ? " <span style='color: #6b7280;'>(×#{hm.turn_in_count})</span>" : "")
        end
      end

      output << ""
      output << "<span style='color: #6b7280;'>Commands: mission &lt;slug&gt; | accept &lt;slug&gt; | turn_in &lt;slug&gt; | abandon &lt;slug&gt;</span>"
      output << "<span style='color: #a78bfa;'>════════════════════════════════════════════════════════════════</span>"
      output.join("\n")
    end

    def format_active_mission_row(hackr_mission)
      m = hackr_mission.grid_mission
      giver = m.giver_mob ? " <span style='color: #6b7280;'>[giver: #{h(m.giver_mob.name)}]</span>" : ""
      arc = m.grid_mission_arc ? " <span style='color: #6b7280;'>[#{h(m.grid_mission_arc.name)}]</span>" : ""

      lines = []
      lines << "  <span style='color: #fbbf24;'>#{h(m.slug)}</span> " \
        "<span style='color: #9ca3af;'>::</span> <span style='color: #22d3ee;'>#{h(m.name)}</span>#{giver}#{arc}"

      all_done, obj_lines = mission_objective_lines(hackr_mission, indent: "    ")
      lines.concat(obj_lines)

      if all_done
        giver_hint = m.giver_mob ? "Return to #{h(m.giver_mob.name)}" : "Ready"
        lines << "    <span style='color: #fbbf24;'>▲ READY FOR TURN-IN</span> <span style='color: #6b7280;'>(#{giver_hint}. 'turn_in #{h(m.slug)}')</span>"
      end

      lines.join("\n")
    end

    # Render the objective checklist for a hackr_mission. Returns
    # [all_done?, Array<String>] so callers can decide whether to append
    # a READY notice. Used by both the summary row (`missions`) and the
    # detail view (`mission <slug>`).
    def mission_objective_lines(hackr_mission, indent:)
      progress_by_obj = hackr_mission.grid_hackr_mission_objectives.index_by(&:grid_mission_objective_id)
      all_done = true
      lines = hackr_mission.grid_mission.grid_mission_objectives.map do |obj|
        hobj = progress_by_obj[obj.id]
        current = hobj&.progress.to_i
        target = obj.target_count.to_i
        done = hobj&.completed_at.present?
        all_done &&= done
        check = done ? "<span style='color: #34d399;'>✓</span>" : "<span style='color: #6b7280;'>▸</span>"
        count_tag = (target > 1) ? " <span style='color: #9ca3af;'>(#{current}/#{target})</span>" : ""
        "#{indent}#{check} #{h(obj.label)}#{count_tag}"
      end
      [all_done, lines]
    end

    def mission_detail_command(slug)
      return "<span style='color: #fbbf24;'>Usage: mission &lt;slug&gt;</span>" if slug.blank?

      # First check active instance (player's current progress view)
      active = hackr.grid_hackr_missions.active.joins(:grid_mission)
        .where(grid_missions: {slug: slug}).first
      if active
        return format_active_mission_detail(active)
      end

      # Otherwise show definition (if in giver's room, show accept hint)
      mission = GridMission.published.find_by(slug: slug)
      return "<span style='color: #f87171;'>No mission with slug '#{h(slug)}'.</span>" unless mission

      room = hackr.current_room
      mission_brief_response(mission.giver_mob, mission, room) || "<span style='color: #9ca3af;'>Nothing to show.</span>"
    end

    def format_active_mission_detail(hackr_mission)
      m = hackr_mission.grid_mission
      output = []
      output << "\n<span style='color: #a78bfa;'>════════════════════════════════════════════════════════════════</span>"
      output << "<span style='color: #22d3ee; font-weight: bold;'>#{h(m.name)}</span>" +
        (m.grid_mission_arc ? " <span style='color: #6b7280;'>[#{h(m.grid_mission_arc.name)}]</span>" : "")
      output << "<span style='color: #a78bfa;'>════════════════════════════════════════════════════════════════</span>"
      output << ""
      output << "<span style='color: #d0d0d0;'>#{h(m.description)}</span>" if m.description.present?
      output << ""
      output << "<span style='color: #fbbf24;'>Objectives:</span>"

      _all_done, obj_lines = mission_objective_lines(hackr_mission, indent: "  ")
      output.concat(obj_lines)

      rewards_summary = mission_rewards_summary(m)
      if rewards_summary.present?
        output << ""
        output << "<span style='color: #fbbf24;'>Rewards:</span> #{rewards_summary}"
      end

      if hackr_mission.all_objectives_completed?
        giver_hint = m.giver_mob ? "Return to #{h(m.giver_mob.name)}" : "Ready"
        output << ""
        output << "<span style='color: #fbbf24;'>▲ READY FOR TURN-IN</span> <span style='color: #6b7280;'>(#{giver_hint}. Use 'turn_in #{h(m.slug)}')</span>"
      end

      output << "<span style='color: #a78bfa;'>════════════════════════════════════════════════════════════════</span>"
      output.join("\n")
    end

    def accept_mission_command(slug)
      return "<span style='color: #fbbf24;'>Usage: accept &lt;slug&gt;</span>" if slug.blank?

      # Dialogue-path gate — can't accept a mission you haven't discovered
      mission = GridMission.published.find_by(slug: slug)
      if mission&.giver_mob_id && mission.dialogue_path.present?
        giver = mission.giver_mob
        if giver && dialogue_path_blocked?(mission, giver)
          return "<span style='color: #f87171;'>You haven't learned about that job yet.</span>"
        end
      end

      room = hackr.current_room
      mission_service.accept!(slug, room: room)

      mission = GridMission.find_by(slug: slug)
      giver = mission&.giver_mob
      giver_line = giver ? " <span style='color: #6b7280;'>from #{h(giver.name)}</span>" : ""

      "<span style='color: #34d399;'>▲ MISSION ACCEPTED:</span> " \
        "<span style='color: #22d3ee;'>#{h(mission&.name)}</span>#{giver_line}\n" \
        "<span style='color: #6b7280;'>Use 'mission #{h(slug)}' to view objectives.</span>"
    rescue Grid::MissionService::MissionMissing,
      Grid::MissionService::NotAtGiver,
      Grid::MissionService::PrereqUnmet,
      Grid::MissionService::ClearanceTooLow,
      Grid::MissionService::RepTooLow,
      Grid::MissionService::AlreadyActive,
      Grid::MissionService::AlreadyCompletedNonRepeatable => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    end

    def abandon_mission_command(slug)
      return "<span style='color: #fbbf24;'>Usage: abandon &lt;slug&gt;</span>" if slug.blank?

      hackr_mission = mission_service.abandon!(slug)
      "<span style='color: #fbbf24;'>Mission abandoned:</span> " \
        "<span style='color: #d0d0d0;'>#{h(hackr_mission.grid_mission.name)}</span>\n" \
        "<span style='color: #6b7280;'>Progress has been cleared. You can re-accept it anytime.</span>"
    rescue Grid::MissionService::NotActive => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    end

    def turn_in_command(slug)
      return "<span style='color: #fbbf24;'>Usage: turn_in &lt;slug&gt;</span>" if slug.blank?

      room = hackr.current_room
      outcome = mission_service.turn_in!(slug, room: room)

      output = outcome[:notification_html]
      output = append_notifications(output, outcome[:progressor_notifs] || [])
      output = append_notifications(output, outcome[:achievement_notifs] || [])
      {output: output, event: nil}
    rescue Grid::MissionService::NotActive,
      Grid::MissionService::ObjectivesIncomplete,
      Grid::MissionService::NotAtTurnIn => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue Grid::InventoryErrors::InventoryFull, Grid::InventoryErrors::StackLimitExceeded => e
      "<span style='color: #f87171;'>Cannot turn in — #{h(e.message)}</span>"
    end

    # "give <item> to <npc>" — consumes the item and fires a :deliver_item
    # mission tick if any active mission has a matching objective. If no
    # objective matches, the item is NOT consumed (flavor-only delivery)
    # and the NPC offers a non-committal line.
    def give_command(args)
      return "<span style='color: #fbbf24;'>Usage: give [qty] &lt;item&gt; to &lt;npc&gt;</span>" if args.length < 3

      # Split on the last occurrence of "to" so multi-word item + NPC names
      # round-trip correctly (e.g. "give 5 Signal Fragment to Codec Prime").
      to_index = args.rindex { |w| w.downcase == "to" }
      return "<span style='color: #fbbf24;'>Usage: give [qty] &lt;item&gt; to &lt;npc&gt;</span>" unless to_index && to_index > 0 && to_index < args.length - 1

      raw_item_part = args[0...to_index].join(" ")
      npc_name = args[(to_index + 1)..].join(" ")

      parsed = Grid::QuantityParser.parse(raw_item_part)
      item_name = parsed.remainder
      return "<span style='color: #fbbf24;'>Usage: give [qty] &lt;item&gt; to &lt;npc&gt;</span>" if item_name.empty?

      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless room

      item = hackr.grid_items.in_inventory(hackr).find_by("LOWER(name) = ?", item_name.downcase)
      return equipped_item_hint(item_name) || "<span style='color: #f87171;'>You don't have '#{h(item_name)}'.</span>" unless item

      qty = (parsed.quantity == :all) ? item.quantity : parsed.quantity
      return "<span style='color: #f87171;'>You only have #{item.quantity} #{h(item.name)} (requested #{qty}).</span>" if qty > item.quantity

      mob = room.grid_mobs.find_by("LOWER(name) = ?", npc_name.downcase)
      return "<span style='color: #f87171;'>You don't see '#{h(npc_name)}' here.</span>" unless mob

      saved_name = item.name

      # Wrap progressor + consumption in one transaction so a mid-flow
      # exception can't leave the objective advanced without the item
      # consumed (free repeat deliveries) or the item gone without
      # progress (lost reward). All-or-nothing.
      notifications = []
      tx_committed = false
      qty_insufficient = false
      begin
        ActiveRecord::Base.transaction do
          item.lock!
          # Re-check after lock — concurrent request may have consumed units
          if qty > item.quantity
            qty_insufficient = true
            raise ActiveRecord::Rollback
          end

          notifications = mission_progressor.record(
            :deliver_item, item_name: saved_name, npc_name: mob.name, amount: qty
          )

          if notifications.empty?
            # No mission objective matched — roll back the transaction
            # so nothing is written and the NPC politely declines. The
            # item stays in the player's inventory.
            raise ActiveRecord::Rollback
          end

          # Consume the items only when a delivery objective matched.
          remaining = item.quantity - qty
          if remaining > 0
            item.update!(quantity: remaining)
          else
            item.destroy!
          end
          tx_committed = true
        end
      ensure
        # If the transaction rolled back (either ActiveRecord::Rollback
        # or an exception from item.destroy!), the progressor's memoized
        # `@active_hackr_missions` holds AR objects whose `completed_at`
        # was mutated in-memory by `save!` before the rollback. Drop
        # the memoization so any subsequent `record` call in this same
        # command execution re-reads from the DB.
        @mission_progressor = nil unless tx_committed
      end

      if qty_insufficient
        return "<span style='color: #f87171;'>You only have #{item.quantity} #{h(saved_name)} (requested #{qty}).</span>"
      end

      if notifications.empty?
        return dialogue_box(
          "<span style='color: #c084fc;'>#{h(mob.name)}</span>: " \
          "<span style='color: #60a5fa;'>\"I appreciate the gesture, but I have no use for that.\"</span>"
        )
      end

      qty_label = (qty > 1) ? " ×#{qty}" : ""
      output = "<span style='color: #34d399;'>You hand </span>" \
        "<span style='color: #d0d0d0;'>#{h(saved_name)}</span>" \
        "<span style='color: #34d399;'>#{h(qty_label)} to </span>" \
        "<span style='color: #c084fc;'>#{h(mob.name)}</span><span style='color: #34d399;'>.</span>"
      append_notifications(output, notifications)
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

    # --- Den commands ---

    def den_command(args)
      subcmd = args.first&.downcase
      sub_args = args[1..] || []

      case subcmd
      when "rename"
        den_rename_command(sub_args.join(" "))
      when "describe", "desc"
        den_describe_command(sub_args.join(" "))
      when "invite"
        den_invite_command(sub_args.first)
      when "uninvite"
        den_uninvite_command(sub_args.first)
      when "lock"
        den_lock_command
      when "unlock"
        den_unlock_command
      when nil
        den_status_command
      else
        "<span style='color: #f87171;'>Unknown den command: #{h(subcmd)}. Try: den rename, den describe, den invite, den uninvite, den lock, den unlock</span>"
      end
    end

    def den_rename_command(name)
      return "<span style='color: #fbbf24;'>Usage: den rename &lt;name&gt;</span>" if name.blank?
      if name.length > 80
        return "<span style='color: #f87171;'>Name is too long (80 character limit).</span>"
      end

      den_service.rename_den!(name)
      "<span style='color: #34d399;'>Den renamed to: #{h(name)}</span>"
    rescue Grid::DenService::DenNotFound => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue ActiveRecord::RecordInvalid => e
      "<span style='color: #f87171;'>#{e.record.errors.full_messages.first}</span>"
    end

    def den_describe_command(text)
      return "<span style='color: #fbbf24;'>Usage: den describe &lt;text&gt;</span>" if text.blank?

      den_service.describe_den!(text)
      "<span style='color: #34d399;'>Den description updated.</span>"
    rescue Grid::DenService::DenNotFound => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue ActiveRecord::RecordInvalid => e
      "<span style='color: #f87171;'>#{e.record.errors.full_messages.first}</span>"
    end

    def den_invite_command(guest_alias)
      return "<span style='color: #fbbf24;'>Usage: den invite &lt;hackr&gt;</span>" if guest_alias.blank?

      invite = den_service.invite!(guest_alias)
      expires_str = invite.expires_at.strftime("%H:%M UTC")
      "<span style='color: #34d399;'>#{h(guest_alias)} invited to your den. Invite expires at #{expires_str}.</span>"
    rescue Grid::DenService::DenNotFound => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue ActiveRecord::RecordNotFound
      "<span style='color: #f87171;'>Hackr '#{h(guest_alias)}' not found.</span>"
    end

    def den_uninvite_command(guest_alias)
      return "<span style='color: #fbbf24;'>Usage: den uninvite &lt;hackr&gt;</span>" if guest_alias.blank?

      den_service.uninvite!(guest_alias)
      "<span style='color: #34d399;'>#{h(guest_alias)} removed from your den invite list.</span>"
    rescue Grid::DenService::DenNotFound => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue ActiveRecord::RecordNotFound
      "<span style='color: #f87171;'>Hackr '#{h(guest_alias)}' not found.</span>"
    end

    def den_lock_command
      den_service.lock_den!(hackr.current_room)
      "<span style='color: #f87171;'>Den locked. No one can enter or leave.</span>"
    rescue Grid::DenService::DenNotFound => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue Grid::DenService::NotInDenOrCorridor
      "<span style='color: #f87171;'>You must be in your den or the Residential Corridor to lock it.</span>"
    end

    def den_unlock_command
      den_service.unlock_den!(hackr.current_room)
      "<span style='color: #34d399;'>Den unlocked.</span>"
    rescue Grid::DenService::DenNotFound => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue Grid::DenService::NotInDenOrCorridor
      "<span style='color: #f87171;'>You must be in your den or the Residential Corridor to unlock it.</span>"
    end

    def den_status_command
      den = hackr.den
      unless den
        return "<span style='color: #9ca3af;'>You don't have a den yet. Use a Den Access Chip to claim one.</span>"
      end

      lines = []
      lines << "<span style='color: #22d3ee; font-weight: bold;'>DEN STATUS :: #{h(den.name)}</span>"
      lines << "<span style='color: #fbbf24;'>Location:</span> <span style='color: #d0d0d0;'>#{h(den.grid_zone.name)}</span>"
      lines << "<span style='color: #fbbf24;'>Floor:</span> <span style='color: #d0d0d0;'>#{den.den_floor_count}/#{Grid::DenService::DEN_STORAGE_CAP} items</span>"

      fixtures = den.placed_fixtures.includes(:stored_items)
      if fixtures.any?
        lines << "<span style='color: #fbbf24;'>Fixtures (#{fixtures.size}/#{Grid::DenService::MAX_DEN_FIXTURES}):</span>"
        fixtures.each do |f|
          used = f.stored_items.size
          cap = f.storage_capacity
          lines << "  <span style='color: #a78bfa;'>#{h(f.name)}</span> <span style='color: #6b7280;'>(#{used}/#{cap} slots)</span>"
        end
      else
        lines << "<span style='color: #6b7280;'>No fixtures installed.</span>"
      end

      lines << "<span style='color: #fbbf24;'>Locked:</span> <span style='color: #{den.locked? ? "#f87171" : "#34d399"};'>#{den.locked? ? "YES" : "NO"}</span>"

      active_invites = GridDenInvite.active.where(hackr: hackr).includes(:guest)
      if active_invites.any?
        lines << "<span style='color: #fbbf24;'>Invited:</span>"
        active_invites.each do |inv|
          lines << "  <span style='color: #a78bfa;'>#{h(inv.guest.hackr_alias)}</span> <span style='color: #6b7280;'>(expires #{inv.expires_at.strftime("%H:%M UTC")})</span>"
        end
      else
        lines << "<span style='color: #6b7280;'>No active invites.</span>"
      end

      lines.join("\n")
    end

    def den_service
      @den_service ||= Grid::DenService.new(hackr)
    end

    # --- Fixture commands ---

    def place_fixture_command(item_name)
      return "<span style='color: #fbbf24;'>Place what? Usage: place &lt;fixture&gt;</span>" if item_name.empty?
      return "<span style='color: #f87171;'>You can only place fixtures in your own den.</span>" unless in_own_den?

      room = hackr.current_room

      item = hackr.grid_items.in_inventory(hackr).find_by("LOWER(name) = ?", item_name.downcase)
      return "<span style='color: #f87171;'>You don't have '#{h(item_name)}'.</span>" unless item
      unless item.fixture?
        return "<span style='color: #f87171;'>#{h(item.name)} is not a fixture.</span>"
      end

      fixture_count = room.placed_fixtures.count
      if fixture_count >= Grid::DenService::MAX_DEN_FIXTURES
        return "<span style='color: #f87171;'>Fixture limit reached (#{fixture_count}/#{Grid::DenService::MAX_DEN_FIXTURES}). Unplace one first.</span>"
      end

      item.update!(room: room, grid_hackr: nil)

      notifications = achievement_checker.check(:place_fixture, item_name: item.name)
      notifications += achievement_checker.check(:fixtures_placed)
      notifications += mission_progressor.record(:place_fixture, item_name: item.name)

      output = "<span style='color: #34d399;'>Installed </span><span style='color: #a78bfa;'>#{h(item.name)}</span><span style='color: #34d399;'>. +#{item.storage_capacity} storage slots.</span>"
      output = append_notifications(output, notifications)
      {output: output, event: nil}
    end

    def unplace_fixture_command(item_name)
      return "<span style='color: #fbbf24;'>Unplace what? Usage: unplace &lt;fixture&gt;</span>" if item_name.empty?
      return "<span style='color: #f87171;'>You can only unplace fixtures from your own den.</span>" unless in_own_den?

      room = hackr.current_room
      item = room.placed_fixtures.find_by("LOWER(name) = ?", item_name.downcase)
      return "<span style='color: #f87171;'>No placed fixture called '#{h(item_name)}' here.</span>" unless item

      if item.stored_items.exists?
        return "<span style='color: #f87171;'>#{h(item.name)} has items stored inside. Retrieve them first.</span>"
      end

      ActiveRecord::Base.transaction do
        hackr.lock!
        used = hackr.grid_items.in_inventory(hackr).count
        if used >= hackr.inventory_capacity
          return "<span style='color: #f87171;'>Inventory full (#{used}/#{hackr.inventory_capacity} slots). Make room first.</span>"
        end

        item.update!(grid_hackr: hackr, room: nil)
      end
      "<span style='color: #34d399;'>#{h(item.name)} uninstalled and returned to inventory.</span>"
    end

    def store_in_fixture_command(args)
      in_idx = args.rindex { |w| w.downcase == "in" }
      unless in_idx && in_idx > 0 && in_idx < args.length - 1
        return "<span style='color: #fbbf24;'>Usage: store [qty] &lt;item&gt; in &lt;fixture&gt;</span>"
      end

      raw_item_part = args[0...in_idx].join(" ")
      fixture_name = args[(in_idx + 1)..].join(" ")

      parsed = Grid::QuantityParser.parse(raw_item_part)
      item_name = parsed.remainder
      return "<span style='color: #fbbf24;'>Usage: store [qty] &lt;item&gt; in &lt;fixture&gt;</span>" if item_name.empty?

      return "<span style='color: #f87171;'>You can only store items in fixtures in your own den.</span>" unless in_own_den?

      room = hackr.current_room
      fixture = room.placed_fixtures.find_by("LOWER(name) = ?", fixture_name.downcase)
      return "<span style='color: #f87171;'>No placed fixture called '#{h(fixture_name)}' here.</span>" unless fixture

      item = hackr.grid_items.in_inventory(hackr).find_by("LOWER(name) = ?", item_name.downcase)
      return "<span style='color: #f87171;'>You don't have '#{h(item_name)}'.</span>" unless item

      if item.fixture?
        return "<span style='color: #f87171;'>You can't store a fixture inside another fixture.</span>"
      end

      saved_name = item.name
      saved_unicorn = item.unicorn?
      fixture_display = fixture.name
      cap = fixture.storage_capacity
      qty = nil

      ActiveRecord::Base.transaction do
        qty = Grid::ItemTransfer.move!(
          source_item: item,
          quantity: parsed.quantity,
          destination_type: :fixture,
          destination: fixture
        )
      end

      stored_count = fixture.stored_items.count
      notifications = achievement_checker.check(:items_stored)
      qty_label = (qty > 1) ? " ×#{qty}" : ""
      name_display = saved_unicorn ? "<span class='rarity-unicorn'>#{h(saved_name)}</span>" : "<span style='color: #d0d0d0;'>#{h(saved_name)}</span>"
      output = "<span style='color: #34d399;'>Stored </span>#{name_display}<span style='color: #34d399;'>#{h(qty_label)} in </span><span style='color: #a78bfa;'>#{h(fixture_display)}</span><span style='color: #34d399;'>. (#{stored_count}/#{cap} slots)</span>"
      output = append_notifications(output, notifications)
      {output: output, event: nil}
    rescue Grid::ItemTransfer::DestinationFull => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue Grid::ItemTransfer::InsufficientQuantity => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    end

    def retrieve_from_fixture_command(args)
      from_idx = args.rindex { |w| w.downcase == "from" }
      unless from_idx && from_idx > 0 && from_idx < args.length - 1
        return "<span style='color: #fbbf24;'>Usage: retrieve [qty] &lt;item&gt; from &lt;fixture&gt;</span>"
      end

      raw_item_part = args[0...from_idx].join(" ")
      fixture_name = args[(from_idx + 1)..].join(" ")

      parsed = Grid::QuantityParser.parse(raw_item_part)
      item_name = parsed.remainder
      return "<span style='color: #fbbf24;'>Usage: retrieve [qty] &lt;item&gt; from &lt;fixture&gt;</span>" if item_name.empty?

      return "<span style='color: #f87171;'>You can only retrieve items from fixtures in your own den.</span>" unless in_own_den?

      room = hackr.current_room
      fixture = room.placed_fixtures.find_by("LOWER(name) = ?", fixture_name.downcase)
      return "<span style='color: #f87171;'>No placed fixture called '#{h(fixture_name)}' here.</span>" unless fixture

      item = fixture.stored_items.find_by("LOWER(name) = ?", item_name.downcase)
      return "<span style='color: #f87171;'>#{h(fixture.name)} doesn't contain '#{h(item_name)}'.</span>" unless item

      saved_name = item.name
      saved_unicorn = item.unicorn?
      fixture_display = fixture.name
      qty = nil

      ActiveRecord::Base.transaction do
        qty = Grid::ItemTransfer.move!(
          source_item: item,
          quantity: parsed.quantity,
          destination_type: :inventory,
          destination: hackr
        )
      end

      qty_label = (qty > 1) ? " ×#{qty}" : ""
      name_display = saved_unicorn ? "<span class='rarity-unicorn'>#{h(saved_name)}</span>" : "<span style='color: #d0d0d0;'>#{h(saved_name)}</span>"
      "<span style='color: #34d399;'>Retrieved </span>#{name_display}<span style='color: #34d399;'>#{h(qty_label)} from </span><span style='color: #a78bfa;'>#{h(fixture_display)}</span><span style='color: #34d399;'>.</span>"
    rescue Grid::InventoryErrors::InventoryFull => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    rescue Grid::ItemTransfer::InsufficientQuantity => e
      "<span style='color: #f87171;'>#{h(e.message)}</span>"
    end

    def peek_fixture_command(fixture_name)
      return "<span style='color: #fbbf24;'>Peek inside what? Usage: peek &lt;fixture&gt;</span>" if fixture_name.empty?

      room = hackr.current_room
      return "<span style='color: #f87171;'>You are nowhere!</span>" unless room

      fixture = room.placed_fixtures.find_by("LOWER(name) = ?", fixture_name.downcase)
      return "<span style='color: #f87171;'>No placed fixture called '#{h(fixture_name)}' here.</span>" unless fixture

      cap = fixture.storage_capacity
      stored = fixture.stored_items.to_a
      slot_color = (stored.count >= cap) ? "#f87171" : "#9ca3af"

      output = []
      output << "<span style='color: #a78bfa; font-weight: bold;'>#{h(fixture.name)}</span> <span style='color: #{slot_color};'>[#{stored.count}/#{cap} slots]</span>"
      if stored.any?
        stored.each do |item|
          name_display = item.unicorn? ? item.rainbow_name_html : "<span style='color: #{item.rarity_color};'>#{h(item.name)}</span>"
          rarity_tag = item.rarity ? " <span style='color: #{item.rarity_color};'>[#{item.rarity_label}]</span>" : ""
          qty_tag = (item.quantity.to_i > 1) ? " <span style='color: #6b7280;'>×#{item.quantity}</span>" : ""
          output << "  ▸ #{name_display}#{rarity_tag}#{qty_tag}"
        end
      else
        output << "  <span style='color: #6b7280;'>Empty.</span>"
      end
      output.join("\n")
    end

    # All den room IDs this hackr can enter: their own + actively invited.
    # Single query, memoized per request. Used by look_command in corridor.
    def accessible_den_room_ids
      @accessible_den_room_ids ||= begin
        ids = Set.new
        ids << hackr.den&.id if hackr.den
        invited_ids = GridDenInvite.active.where(guest: hackr).pluck(:den_id)
        ids.merge(invited_ids)
        ids
      end
    end
  end
end
