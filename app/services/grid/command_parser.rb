module Grid
  class CommandParser
    attr_reader :hackr, :input, :event

    def initialize(hackr, input)
      @hackr = hackr
      @input = input.to_s.strip
      @event = nil
    end

    def execute
      return {output: "Please enter a command.", event: nil} if input.empty?

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
      when "help", "?"
        help_command
      when "who"
        who_command
      when "clear", "cls"
        clear_command
      else
        "Unknown command: #{command}. Type 'help' for a list of commands."
      end

      # Normalize result to hash format
      result.is_a?(Hash) ? result : {output: result, event: nil}
    end

    private

    def look_command
      room = hackr.current_room
      return "You are nowhere. This shouldn't happen!" unless room

      output = []
      output << "\n#{room.name.upcase}"
      output << "[#{room.color_scheme}]" if room.color_scheme
      output << ""
      output << room.description if room.description
      output << ""

      # Show exits
      exits = room.exits_from.includes(:to_room)
      if exits.any?
        exit_list = exits.map { |e| "#{e.direction} (#{e.to_room.name})" }.join(", ")
        output << "Exits: #{exit_list}"
      else
        output << "Exits: none"
      end

      # Show items
      items = room.grid_items.in_room(room)
      if items.any?
        output << ""
        output << "Items: #{items.map(&:name).join(", ")}"
      end

      # Show Mobs
      mobs = room.grid_mobs
      if mobs.any?
        output << ""
        output << "Mobs: #{mobs.map(&:name).join(", ")}"
      end

      # Show other hackrs
      other_hackrs = room.grid_hackrs.where.not(id: hackr.id)
      if other_hackrs.any?
        output << ""
        output << "Hackrs: #{other_hackrs.map(&:hackr_alias).join(", ")}"
      end

      output.join("\n")
    end

    def go_command(direction)
      return "Go where? Specify a direction: north, south, east, west, up, down" unless direction

      old_room = hackr.current_room
      return "You are nowhere!" unless old_room

      exit = old_room.exits_from.find_by(direction: direction)
      return "You can't go #{direction} from here." unless exit

      if exit.locked
        return "The exit is locked." unless exit.requires_item && hackr.grid_items.exists?(exit.requires_item_id)
      end

      new_room = exit.to_room
      hackr.update!(current_room: new_room)

      {
        output: look_command,
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
      return "Say what?" if message.empty?

      GridMessage.create!(
        grid_hackr: hackr,
        room: hackr.current_room,
        message_type: "say",
        content: message
      )

      {
        output: "[#{hackr.hackr_alias}]: #{message}",
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
      if items.any?
        "Inventory:\n" + items.map { |item| "  - #{item.name}" }.join("\n")
      else
        "Your inventory is empty."
      end
    end

    def take_command(item_name)
      return "Take what?" if item_name.empty?

      room = hackr.current_room
      return "You are nowhere!" unless room

      item = room.grid_items.in_room(room).find_by("LOWER(name) = ?", item_name.downcase)
      return "You don't see '#{item_name}' here." unless item

      item.update!(grid_hackr: hackr, room: nil)

      {
        output: "You take the #{item.name}.",
        event: {
          type: "take",
          hackr_alias: hackr.hackr_alias,
          item_name: item.name,
          room_id: room.id
        }
      }
    end

    def drop_command(item_name)
      return "Drop what?" if item_name.empty?

      item = hackr.grid_items.find_by("LOWER(name) = ?", item_name.downcase)
      return "You don't have '#{item_name}'." unless item

      room = hackr.current_room
      item.update!(room: room, grid_hackr: nil)

      {
        output: "You drop the #{item.name}.",
        event: {
          type: "drop",
          hackr_alias: hackr.hackr_alias,
          item_name: item.name,
          room_id: room.id
        }
      }
    end

    def examine_command(target)
      return "Examine what?" if target.empty?

      room = hackr.current_room
      return "You are nowhere!" unless room

      # Check items in room
      item = room.grid_items.in_room(room).find_by("LOWER(name) = ?", target.downcase)
      return item.description if item

      # Check items in inventory
      item = hackr.grid_items.find_by("LOWER(name) = ?", target.downcase)
      return item.description if item

      # Check Mobs
      mob = room.grid_mobs.find_by("LOWER(name) = ?", target.downcase)
      return mob.description if mob

      "You don't see '#{target}' here."
    end

    def help_command
      <<~HELP
        Available Commands:

        Navigation:
          look, l                 - Look around the room
          go <direction>          - Move in a direction
          north, n / south, s     - Move north/south
          east, e / west, w       - Move east/west
          up, u / down, d         - Move up/down

        Items:
          inventory, inv, i       - View your inventory
          take <item>             - Pick up an item
          drop <item>             - Drop an item
          examine <target>, x     - Examine an item or NPC

        Social:
          say <message>           - Say something in the room
          who                     - See who's online

        Utility:
          clear, cls              - Clear the screen
          help, ?                 - Show this help message
      HELP
    end

    def who_command
      online = GridHackr.where.not(current_room: nil).order(:hackr_alias)
      if online.any?
        "Online Hackrs:\n" + online.map { |h| "  - #{h.hackr_alias} (#{h.current_room&.name || "nowhere"})" }.join("\n")
      else
        "No hackrs are currently online."
      end
    end

    def clear_command
      {
        output: "",
        event: {type: "clear"}
      }
    end
  end
end
