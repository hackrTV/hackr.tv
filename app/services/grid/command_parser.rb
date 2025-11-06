module Grid
  class CommandParser
    attr_reader :hackr, :input

    def initialize(hackr, input)
      @hackr = hackr
      @input = input.to_s.strip
    end

    def execute
      return "Please enter a command." if input.empty?

      command, *args = input.downcase.split

      case command
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
      else
        "Unknown command: #{command}. Type 'help' for a list of commands."
      end
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

      # Show NPCs
      npcs = room.grid_npcs
      if npcs.any?
        output << ""
        output << "NPCs: #{npcs.map(&:name).join(", ")}"
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

      room = hackr.current_room
      return "You are nowhere!" unless room

      exit = room.exits_from.find_by(direction: direction)
      return "You can't go #{direction} from here." unless exit

      if exit.locked
        return "The exit is locked." unless exit.requires_item && hackr.grid_items.exists?(exit.requires_item_id)
      end

      hackr.update!(current_room: exit.to_room)
      look_command
    end

    def say_command(message)
      return "Say what?" if message.empty?

      GridMessage.create!(
        grid_hackr: hackr,
        room: hackr.current_room,
        message_type: "say",
        content: message
      )

      "[#{hackr.hackr_alias}]: #{message}"
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
      "You take the #{item.name}."
    end

    def drop_command(item_name)
      return "Drop what?" if item_name.empty?

      item = hackr.grid_items.find_by("LOWER(name) = ?", item_name.downcase)
      return "You don't have '#{item_name}'." unless item

      item.update!(room: hackr.current_room, grid_hackr: nil)
      "You drop the #{item.name}."
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

      # Check NPCs
      npc = room.grid_npcs.find_by("LOWER(name) = ?", target.downcase)
      return npc.description if npc

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

        Help:
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
  end
end
